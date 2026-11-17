require "test_helper"

class SyncJobTest < ActiveJob::TestCase
  test "sync is performed" do
    syncable = accounts(:depository)

    sync = syncable.syncs.create!(window_start_date: 2.days.ago.to_date)

    sync.expects(:perform).once

    SyncJob.perform_now(sync)
  end
  %w[family account].each do |kind|
    [ false, true ].each do |balances_only|
      test "#{kind} sync uses family locale and keeps balances_only #{balances_only}" do
        family = families(:dylan_family)
        family.update!(locale: "vi")
        syncable = kind == "family" ? family : accounts(:depository)
        syncable.family.reload if kind == "account"
        sync = Sync.create!(syncable: syncable)
        observed = nil
        syncable.define_singleton_method(:perform_sync) do |running_sync|
          observed = [ I18n.locale, running_sync.balances_only? ]
        end

        I18n.with_locale(:en) do
          SyncJob.perform_now(sync, balances_only: balances_only)
          assert_equal [ :vi, balances_only ], observed
          assert_equal :en, I18n.locale
        end
      end
    end
  end

  test "sync restores worker locale when provider raises" do
    account = accounts(:depository)
    account.family.update!(locale: "vi")
    sync = account.syncs.create!
    account.expects(:perform_sync).with { I18n.locale == :vi }.raises(StandardError, "provider failure")

    I18n.with_locale(:en) do
      SyncJob.perform_now(sync)
      assert_equal :en, I18n.locale
    end
    assert sync.reload.failed?
    assert_equal "provider failure", sync.error
  end

  test "sync restores worker locale when an exception escapes the sync state guard" do
    sync = families(:dylan_family).syncs.create!
    sync.syncable.update!(locale: "vi")
    sync.expects(:may_start?).with { I18n.locale == :vi }.raises(StandardError, "state failure")

    I18n.with_locale(:en) do
      error = assert_raises(StandardError) { SyncJob.perform_now(sync) }
      assert_equal "state failure", error.message
      assert_equal :en, I18n.locale
    end
  end

end
