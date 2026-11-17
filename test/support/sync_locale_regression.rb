# Run with plain Ruby 3.4 when the Rails gems/database are unavailable.
# Executes the real SyncJob and Sync methods against small in-memory boundaries.
abort "Run this harness in a standalone Ruby process" if defined?(Rails)

require "prism"

module I18n
  class << self
    attr_accessor :locale
    def default_locale = :en
    def with_locale(value)
      previous = locale
      self.locale = value.to_sym
      yield
    ensure
      self.locale = previous
    end
  end
  self.locale = :en
end

class Object
  def presence = self
  def present? = true
end

class NilClass
  def presence = nil
  def present? = false
end

class Time
  def self.zone = "UTC"
  def self.use_zone(_zone) = yield
end

module Rails
  def self.logger = self
  def self.tagged(*) = yield
  def self.warn(*) = nil
end

class ApplicationJob
  def self.queue_as(*) = nil
end

class Family
  attr_reader :locale, :observed
  attr_accessor :failure
  def initialize(locale) = @locale = locale
  def resolved_time_zone = "UTC"
  def perform_sync(sync)
    @observed = [ I18n.locale, sync.balances_only? ]
    raise "provider failure" if failure
  end
end

class Account
  attr_reader :family
  def initialize(family) = @family = family
  def perform_sync(sync) = family.perform_sync(sync)
  def observed = family.observed
  def failure=(value)
    family.failure = value
  end
end

class Sync
  attr_reader :syncable, :error, :reported_locale, :finalized_locale
  attr_accessor :guard_failure
  def initialize(syncable) = @syncable = syncable
  def id = 1
  def syncable_id = 1
  def syncable_type = syncable.class.name
  def may_start?
    raise "state failure" if guard_failure
    true
  end
  def start! = nil
  def may_fail? = true
  def fail! = nil
  def with_lock = yield
  def update(error:) = @error = error
  def report_error(_error) = @reported_locale = I18n.locale
  def finalize_if_all_children_finalized = @finalized_locale = I18n.locale
end

# Import method bodies with their real Ruby syntax, not rewritten test copies.
root = Prism.parse_file("app/models/sync.rb").value
walk = lambda do |node|
  if node.is_a?(Prism::DefNode) && %i[perform family].include?(node.name)
    Sync.class_eval(node.location.slice, "app/models/sync.rb", node.location.start_line)
  end
  node.compact_child_nodes.each { |child| walk.call(child) }
end
walk.call(root)
Sync.class_eval { private :family }
load "app/jobs/sync_job.rb"

def assert_equal(expected, actual)
  raise "Expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
end

[Family, Account].each do |kind|
  [false, true].each do |balances_only|
    family = Family.new("vi")
    owner = kind == Family ? family : Account.new(family)
    sync = Sync.new(owner)
    SyncJob.new.perform(sync, balances_only: balances_only)
    assert_equal [:vi, balances_only], owner.observed
    assert_equal :vi, sync.finalized_locale
    assert_equal :en, I18n.locale
  end
end

sync = Sync.new(Family.new("vi"))
sync.define_singleton_method(:balances_only?) { false }
sync.perform
assert_equal [:vi, false], sync.syncable.observed
assert_equal :en, I18n.locale

owner = Account.new(Family.new("vi"))
owner.failure = true
sync = Sync.new(owner)
SyncJob.new.perform(sync)
assert_equal "provider failure", sync.error
assert_equal :vi, sync.reported_locale
assert_equal :vi, sync.finalized_locale
assert_equal :en, I18n.locale

sync = Sync.new(Family.new("vi"))
sync.guard_failure = true
begin
  SyncJob.new.perform(sync)
  raise "Expected the state failure to escape"
rescue RuntimeError => error
  assert_equal "state failure", error.message
end
assert_equal :en, I18n.locale
puts "PASS: 4 family/account flag cases, direct sync, provider failure and escaping failure; locale restored"
