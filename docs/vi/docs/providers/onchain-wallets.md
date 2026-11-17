[English](../../../providers/onchain-wallets.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="on-chain-self-custody-wallets"></a>
# Ví on-chain tự quản lý khóa

Sure có thể theo dõi ví mà bạn tự giữ khóa — Bitcoin, sáu mạng EVM, Solana, Polkadot và Cosmos Hub — **chỉ bằng địa chỉ công khai**. Không ký bất cứ thứ gì, không bao giờ nhập khóa hay cụm từ khôi phục, và không mạng nào yêu cầu API key.

Tài liệu này trình bày nguồn dữ liệu, cấu hình cần thiết, các giới hạn bạn sẽ gặp và cách chẩn đoán khi thông tin ví có vẻ không đúng.

<a id="what-gets-tracked"></a>
## Những gì được theo dõi

Một tài khoản Sure được tạo cho mỗi **tài sản**, trên mỗi **địa chỉ**, thuộc mỗi **mạng**. Ví giữ ETH và USDC trên Ethereum sẽ thành hai tài khoản, đều thuộc loại Crypto với kiểu con "wallet".

Với mỗi tài sản, Sure ghi nhận:

- **Số lượng** nắm giữ, đọc từ blockchain;
- Một **khoản nắm giữ** được định giá theo giá hiện tại, hoặc bằng không khi không có giá;
- Các **khoản chuyển vào và ra**, dưới dạng giao dịch đầu tư khi biết giá của ngày đó, để tái dựng giá vốn và biểu đồ giá trị ngược về thời điểm mua. Khi chưa biết giá ngày đó, khoản chuyển vẫn xuất hiện dưới dạng bút toán có số tiền bằng không và bị loại khỏi tổng, để bạn biết giao dịch đã diễn ra mà không đưa giá trị bịa đặt vào lịch sử. Nó được chuyển thành giao dịch đầu tư trong lần đồng bộ đầu tiên sau khi có giá.

Số dư chỉ đọc và luôn lấy từ blockchain. Sửa thủ công không có tác dụng lâu dài: lần đồng bộ tiếp theo sẽ ghi đè.

<a id="prices-need-two-settings-not-one-read-this-first"></a>
## Giá cần hai thiết lập, không chỉ một (hãy đọc trước)

Nguồn dữ liệu on-chain báo cáo **số lượng, không phải giá trị**. Giá đến từ các nhà cung cấp dữ liệu thị trường của Sure; nhà cung cấp duy nhất có thể báo giá theo ký hiệu tiền mã hóa đơn thuần là **Binance public** (không cần khóa).

Nếu chưa bật nhà cung cấp dữ liệu thị trường hỗ trợ tiền mã hóa, mọi ví on-chain đều được theo dõi về số lượng nhưng **định giá bằng không**. Đây là vấn đề được báo cho bộ phận hỗ trợ nhiều nhất với tính năng này; nguyên nhân nằm ở thiết lập, không phải lỗi đồng bộ.

Cả bảng cài đặt và hộp thoại liên kết đều cảnh báo trước khi bạn liên kết bất kỳ ví nào. Trên bản tự lưu trữ, quản trị viên có thể sửa ngay từ cảnh báo bằng **Enable crypto prices** — thao tác này thêm `binance_public` vào các nhà cung cấp đã bật và giữ nguyên những nhà cung cấp khác. Hoặc bật tại **Settings → Self hosting → Market data providers**, hay đặt `SECURITIES_PROVIDERS` thành danh sách phân cách bằng dấu phẩy có chứa `binance_public`. Trên bản do đơn vị vận hành quản lý, đây là thiết lập của đơn vị đó nên nút này không xuất hiện.

<a id="and-an-exchange-rate-if-your-currency-is-not-usd"></a>
### Cần cả tỷ giá nếu tiền tệ của bạn không phải USD

Nhà cung cấp giá tiền mã hóa báo giá bằng USD, nên định giá ví theo đồng tiền khác của hộ gia đình cần một bước quy đổi. Nhà cung cấp tỷ giá mặc định của Sure (`twelve_data`) yêu cầu API key. Nếu không có khóa và hộ gia đình không dùng USD thì hoàn toàn không có tỷ giá quy đổi; mọi ví on-chain lại được định giá bằng không vì nguyên nhân thứ hai, độc lập này.

Đặt `EXCHANGE_RATE_PROVIDER` (hoặc qua **Settings → Self hosting**) thành nhà cung cấp bạn có thể sử dụng; `frankfurter` không cần API key. Giao diện liên kết cảnh báo cụ thể về thiếu sót này và nêu tên đồng tiền của bạn. Hộ gia đình dùng USD không bao giờ thấy cảnh báo vì không cần quy đổi.

Khi tài sản được định giá bằng không do một trong hai nguyên nhân, hệ thống ghi sự kiện vào **Settings → Debug logs**, dưới nhà cung cấp `onchain_wallet`, kèm danh sách nguyên nhân để xem được mà không cần tái hiện lỗi.

<a id="data-sources"></a>
## Nguồn dữ liệu

| Mạng | Nguồn | Cần khóa | Cấu hình ghi đè |
|---|---|---|---|
| Bitcoin | REST API của [mempool.space](https://mempool.space) | Không | `MEMPOOL_SPACE_URL` |
| Ethereum | Blockscout (`eth.blockscout.com`) | Không | `BLOCKSCOUT_ETHEREUM_URL` |
| Base | Blockscout (`base.blockscout.com`) | Không | `BLOCKSCOUT_BASE_URL` |
| Arbitrum | Blockscout (`arbitrum.blockscout.com`) | Không | `BLOCKSCOUT_ARBITRUM_URL` |
| Optimism | Blockscout (`optimism.blockscout.com`) | Không | `BLOCKSCOUT_OPTIMISM_URL` |
| Polygon | Blockscout (`polygon.blockscout.com`) | Không | `BLOCKSCOUT_POLYGON_URL` |
| Gnosis | Blockscout (`gnosis.blockscout.com`) | Không | `BLOCKSCOUT_GNOSIS_URL` |
| Solana | JSON-RPC công khai (`api.mainnet-beta.solana.com`) | Không | `SOLANA_RPC_URL` |
| Tên token Solana | Tìm kiếm token Jupiter (`lite-api.jup.ag`) | Không | `SOLANA_TOKEN_LIST_URL` |
| Cosmos Hub | Node REST công khai (`cosmos-rest.publicnode.com`) | Không | `COSMOS_REST_URL` |
| Polkadot | Asset Hub Sidecar công khai của Parity | Không | `POLKADOT_SIDECAR_URL` (phải là Asset Hub Sidecar) |

Mỗi cấu hình ghi đè nhận URL gốc của một dịch vụ tương thích, không có dấu gạch chéo cuối. Điều này hữu ích khi bạn tự vận hành indexer hoặc node, hay khi endpoint công khai giới hạn tần suất truy cập.

<a id="optional-etherscan-key"></a>
### Khóa Etherscan tùy chọn

Ethereum, và chỉ Ethereum, có thể được đọc qua Etherscan thay cho Blockscout. Khóa chỉ đem lại giới hạn tần suất cao hơn, không có lợi ích nào khác. Thêm khóa tại **Settings → Providers → On-chain wallets → Advanced**; khóa được lưu mã hóa theo từng hộ gia đình.

Khóa chỉ chuyển việc lấy **lịch sử chuyển tiền** sang Etherscan. Số dư và việc nhận diện mạng luôn lấy từ indexer không cần khóa, vì Etherscan không có endpoint miễn phí liệt kê token của một địa chỉ. Cộng dồn lịch sử chuyển tiền sẽ sai với token rebasing, và chắc chắn sai với dữ liệu cũ hơn giới hạn lịch sử. Lịch sử là phần công việc cần phân trang và chịu giới hạn tần suất, nên đây là nơi khóa thực sự giúp ích. Để trống trường này trừ khi bạn đang bị giới hạn tần suất.

<a id="rate-limits-and-request-cost"></a>
## Giới hạn tần suất và số request

Tất cả endpoint mặc định đều miễn phí và dùng chung nên có giới hạn tần suất. Mỗi client tự giãn các request và thử lại khi nhận 429 với thời gian chờ tăng theo cấp số nhân. Với mỗi lần đồng bộ, trên mỗi địa chỉ, số request xấp xỉ:

| Mạng | Request mỗi lần đồng bộ |
|---|---|
| Bitcoin | 1 + tối đa 10 trang lịch sử |
| EVM | 1 bản tổng hợp + tối đa 10 trang chuyển tiền + tối đa 10 trang chuyển token |
| Solana | ~2 + tối đa 25 lượt đọc giao dịch |
| Cosmos Hub | 3, cộng thêm một trang cho mỗi 200 validator được stake thêm |
| Polkadot | 1 |

Mặc định lịch sử giới hạn ở 10 trang mỗi nguồn — 250 giao dịch với Bitcoin, 10 trang cho mỗi tập dữ liệu EVM — và 25 giao dịch với Solana, vốn tốn một request mỗi giao dịch thay vì mỗi trang. Ví có lịch sử dài hơn vẫn có **số dư hiện tại chính xác** — số dư lấy từ bản tổng hợp địa chỉ, không bao giờ tính từ lịch sử — nhưng các khoản chuyển cũ nhất không được nhập.

Tăng cả hai giới hạn qua `ONCHAIN_HISTORY_MAX_PAGES` (mặc định 10, tối đa 200); hạn mức Solana tăng theo cùng tỷ lệ. Số request trong bảng trên cũng tăng tương ứng, nên chỉ tăng khi tự vận hành node hoặc indexer thay vì dùng endpoint công khai.

**Lịch sử được lấy trong khả năng tốt nhất; số dư thì phải chính xác.** Nếu nguồn từ chối hoặc timeout khi đọc lịch sử phân trang, hệ thống vẫn ghi số dư và đánh dấu lịch sử chưa đầy đủ, thay vì làm hỏng toàn bộ lượt đọc. Điều này quan trọng với endpoint Solana miễn phí, vốn thường xuyên hạn chế `getTransaction`: nếu thiếu cơ chế này, ví Solana sẽ không hiển thị gì thay vì cho thấy tài sản đang giữ.

Khi chạm giới hạn, địa chỉ bị ảnh hưởng được ghi chú trong **Manage wallets**, và sự kiện được ghi tại **Settings → Debug logs** dưới nhà cung cấp `onchain_wallet` — một lần cho mỗi địa chỉ trong mỗi lần đồng bộ, không phải cứ mỗi đêm lại ghi mãi.

<a id="how-many-tokens-one-address-surfaces"></a>
### Số token được hiển thị cho một địa chỉ

Địa chỉ thực tế thường nhận rất nhiều airdrop: một địa chỉ Ethereum nổi tiếng giữ gần 8.000 token ERC-20, còn một địa chỉ Solana tương tự có gần 3.000 tài khoản token. Liệt kê tất cả sẽ khiến màn hình xem xét khó sử dụng, nên mỗi lần đọc hiển thị tối đa **200 token** trên một địa chỉ; có thể điều chỉnh qua `ONCHAIN_MAX_TOKENS_PER_ADDRESS` (tối đa 5.000).

Đồng tiền gốc của mạng không bao giờ bị giới hạn này ảnh hưởng; tài sản đã được theo dõi vẫn tiếp tục đồng bộ trong mọi trường hợp. Trên EVM, token được giữ lại theo thứ hạng vốn hóa thị trường do indexer báo cáo, giúp tài sản thực vượt qua giới hạn còn token airdrop rơi xuống cuối. Solana RPC không cung cấp tín hiệu tương tự, nên sắp xếp theo địa chỉ mint — thứ tự tùy ý nhưng nhất quán giữa các lần đồng bộ, tránh việc giới hạn làm danh sách ví bị xáo trộn mỗi đêm. Khi áp dụng, giới hạn được nêu trên màn hình xem xét và trong Manage wallets.

Nhận diện mạng của một địa chỉ tốn **đúng một request cho mỗi mạng ứng viên**, không bao giờ đọc lịch sử. Nếu explorer ngừng hoạt động trong lúc nhận diện, mạng đó chỉ báo "nothing found" thay vì làm hỏng toàn bộ luồng; bạn vẫn có thể chọn mạng thủ công.

<a id="linking-a-wallet"></a>
## Liên kết ví

**Settings → Providers → On-chain wallets → Add wallet.**

1. Dán địa chỉ công khai. Giữ mạng ở "Detect automatically" trừ khi bạn đã biết muốn chọn mạng nào.
2. Nếu định dạng địa chỉ dùng được cho nhiều mạng — mọi địa chỉ `0x` hợp lệ trên cả sáu mạng EVM, còn định dạng Base58 của Bitcoin trùng một phần với Solana — Sure thăm dò từng mạng rồi yêu cầu bạn chọn, đánh dấu những mạng tìm thấy hoạt động.
3. Chọn tài sản cần theo dõi. Đồng tiền gốc và tài sản được nguồn dữ liệu coi là đáng chú ý sẽ được chọn sẵn; các tài sản còn lại được liệt kê nhưng chưa chọn. “Đáng chú ý” nghĩa là khoản nắm giữ đã có giá và trị giá hơn một đô la trên EVM, hoặc nằm trong danh sách token đã xác minh của Solana — vì airdrop có thể dùng ký hiệu trông hoàn toàn hợp lệ, nên chỉ ký hiệu không chứng minh được gì. Với địa chỉ nhận nhiều airdrop, tiêu chí này tạo ra khác biệt giữa chỉ vài tài sản được chọn sẵn và hai trăm tài sản. Bạn vẫn có thể theo dõi mọi tài sản được liệt kê; tài sản không định giá được sẽ có số lượng và giá trị bằng không.

Không nhập bất kỳ tài sản nào bạn chưa chọn.

<a id="managing-a-wallet"></a>
## Quản lý ví

**Settings → Providers → On-chain wallets → Manage wallets.**

- **Review tokens** — mở lại phần chọn tài sản, giữ nguyên địa chỉ. Dùng để bắt đầu theo dõi token mới nhận hoặc ngừng theo dõi token không còn muốn theo dõi.
- **Stop tracking** (theo từng tài sản) — ngừng theo dõi một tài sản.
- **Change address** — sửa địa chỉ, giữ lại các tài khoản, khoản nắm giữ và lịch sử số dư gắn với nó.
- **Disconnect wallet** — ngừng theo dõi mọi tài sản tại một địa chỉ.

Ngắt kết nối không bao giờ xóa tài khoản. Liên kết nhà cung cấp bị gỡ, các khoản nắm giữ được tách ra, và dữ liệu bạn nhìn thấy vẫn tồn tại dưới dạng tài khoản thủ công không còn cập nhật. Nếu muốn xóa hẳn, hãy xóa chính tài khoản đó.

Mỗi địa chỉ chỉ được theo dõi một lần trên mỗi mạng. Để đổi tài sản đang theo dõi, dùng Review tokens thay vì thêm lại địa chỉ.

<a id="limitations"></a>
## Giới hạn

**Chỉ token được nhà cung cấp giá tiền mã hóa báo giá mới có giá trị, và nhà cung cấp báo giá theo ký hiệu.** Đây là giới hạn lớn nhất của tính năng, nên hãy đọc trước khi đánh giá một con số bạn cho là sai. Định giá đi qua mã `CRYPTO:<SYMBOL>`, trong khi ký hiệu không phải định danh token — hợp đồng mới là định danh. Thực tế, nhà cung cấp chủ yếu bao phủ tài sản lớn: đo trên một địa chỉ Ethereum thật, chỉ hai trong mười khoản nắm giữ token lớn nhất có báo giá. Tám khoản còn lại — bao gồm các khoản khoảng $406,000, $141,000 và $74,000 — có giá trị bằng không dù số lượng được theo dõi đúng.

Vì vậy, **giá trị bằng không cạnh token mà bạn biết có giá trị gần như luôn có nghĩa nhà cung cấp không niêm yết token đó, không phải số dư sai.** Hãy kiểm tra số lượng được đọc trực tiếp từ blockchain. Đồng tiền gốc (BTC, ETH, SOL, POL, XDAI) và token vốn hóa lớn được bao phủ tốt.

Định giá theo địa chỉ hợp đồng thay vì ký hiệu sẽ khắc phục phần lớn thiếu sót, và dữ liệu cũng đã sẵn gần đó: indexer EVM trả tỷ giá cho từng token, còn Jupiter trả giá USD cho từng mint; phiên bản này chưa dùng cả hai để định giá. Thay đổi đó thuộc cách đưa tiền mã hóa vào pipeline giá của Sure, không thuộc riêng tính năng này, nên hiện không thể khắc phục chỉ bằng cấu hình.

**Hoàn toàn không đọc được các vị thế DeFi.** ETH đã stake, token pool thanh khoản, vị thế cho vay và tài khoản stake Solana đều không được nhìn thấy: chỉ đọc đồng tiền gốc và token có thể thay thế được giữ trực tiếp tại địa chỉ. Ví có phần lớn giá trị trong giao thức staking hoặc cho vay chỉ báo một phần giá trị đó. Đây là giới hạn phạm vi, không phải lỗi — UI không tuyên bố đã kiểm tra các vị thế này.

**Bitcoin chỉ theo dõi từng địa chỉ.** Khóa mở rộng (`xpub`, `ypub`, `zpub`) không được hỗ trợ và bị từ chối khi nhập làm địa chỉ. Điều này quan trọng: phần lớn ví Bitcoin là ví HD, trong đó một khóa mở rộng sinh ra hàng nghìn địa chỉ và tiền thừa được gửi về các địa chỉ dẫn xuất. Theo dõi một địa chỉ của ví như vậy chỉ báo số dư của địa chỉ đó, thường là một phần của toàn ví. Hỗ trợ khóa mở rộng cần phép dẫn xuất BIP32 — dependency mà codebase này chủ động tránh — hoặc backend lập chỉ mục descriptor. Nếu bạn dùng ví một địa chỉ hoặc muốn theo dõi một địa chỉ cụ thể, tính năng hoạt động đúng như mong đợi.

**Tên token Solana phụ thuộc danh sách token.** RPC trả mint, không trả tên; tên được lấy từ tìm kiếm token Jupiter và chỉ áp dụng với mint được báo là *đã xác minh*. Bất kỳ ai cũng có thể tạo token tự gọi là USDC, nên mint chưa xác minh hoặc không xác định giữ nhãn tạo từ địa chỉ mint và chỉ được theo dõi số lượng, thay vì gán giá của tài sản thật. Một số mint lớn có thể được nhận diện không cần danh sách nên vẫn hoạt động khi không truy cập được danh sách. Tên được cache 24 giờ cho mỗi mint, kể cả kết quả không tìm thấy.

**Cosmos Hub không có lịch sử chuyển tiền.** Node công khai không lập chỉ mục giao dịch, nên chỉ đọc số dư ATOM: phần có thể chi tiêu, đã stake và đang unbonding; không gồm phần thưởng chưa nhận hoặc token IBC. Không nhập các khoản chuyển trong quá khứ.

**Polkadot không có lịch sử chuyển tiền.** Không có nguồn không cần khóa nào lập chỉ mục các khoản chuyển, nên chỉ đọc số dư DOT trên Asset Hub, gồm cả DOT đã stake. Không đọc các token Asset Hub khác. Không nhập các khoản chuyển trong quá khứ.

**Phí không được tách riêng.** Phí mạng nằm trong tác động ròng của mỗi khoản chuyển, thay vì được ghi riêng. Trên Solana, thay đổi số dư đồng tiền gốc dưới 0.0001 SOL được coi là phí và bị bỏ qua.

**Tài sản qua bridge được chuẩn hóa.** USDC.e, USDbC, USDT0, WETH và các dạng tương tự có thể quy đổi 1:1 được theo dõi như tài sản chuẩn tương ứng, nên cùng tài sản trên hai mạng là một Security thay vì hai.

**Giá theo ngày và được báo bằng USD.** Giá trị được quy đổi sang tiền tệ của hộ gia đình bằng tỷ giá của Sure. Khoản chuyển vào ngày không có giá trở thành bút toán có số tiền bằng không và bị loại khỏi tổng, thay vì giao dịch đầu tư.

**Không theo dõi NFT.** NFT được lọc theo tiêu chuẩn token, nên không bị nhầm thành số dư một đơn vị token có thể thay thế.

<a id="troubleshooting"></a>
## Xử lý sự cố

**Mọi ví đều có giá trị bằng không.** Hoặc chưa bật nhà cung cấp dữ liệu thị trường hỗ trợ tiền mã hóa, hoặc hộ gia đình dùng đồng tiền khác USD nhưng chưa cấu hình nhà cung cấp tỷ giá. Cả hai được giải thích ở trên; UI liên kết cho biết nguyên nhân nào áp dụng.

**Một token bằng không trong khi các token khác cùng ví bình thường.** Nguyên nhân khác: nhà cung cấp giá không báo giá token đó. Giá được tra theo ký hiệu và chủ yếu bao phủ tài sản lớn, nên token ít phổ biến chỉ được theo dõi số lượng và có giá trị bằng không. Xem “Giới hạn” — không có thiết lập nào thay đổi điều này.

**Số dư Bitcoin thấp hơn nhiều so với ứng dụng ví.** Bạn đang theo dõi một địa chỉ của ví HD. Xem “Giới hạn”.

**Đồng bộ báo không truy cập được explorer.** Endpoint công khai đang ngừng hoạt động, giới hạn bạn hoặc phản hồi quá chậm. Thử lại sau, hoặc đặt cấu hình ghi đè `*_URL` tương ứng trỏ đến dịch vụ của bạn. Đây là thông báo cho mọi lỗi truyền tải — kết nối bị từ chối, timeout, lỗi TLS — khác với thông báo chung "something went wrong", vốn biểu thị lỗi phần mềm cần báo cáo.

**Solana có số dư nhưng không có các khoản chuyển.** Endpoint miễn phí giới hạn các phương thức đọc lịch sử; số dư được giữ lại và lịch sử bị đánh dấu chưa đầy đủ. Đặt `SOLANA_RPC_URL` trỏ đến node riêng hoặc endpoint trả phí để lấy các khoản chuyển.

**Solana timeout hoàn toàn với ví rất lớn.** `getTokenAccountsByOwner` trả tất cả tài khoản token trong một phản hồi; endpoint công khai khó xử lý ví có hàng nghìn tài khoản (một ví nổi tiếng có ~2.800). Cách sửa tương tự: trỏ `SOLANA_RPC_URL` đến một node đủ khả năng phục vụ.

**Token vừa nhận không xuất hiện.** Tài sản mới không bao giờ được nhập tự động. Dùng **Review tokens** và chọn nó.

**Token Solana hiển thị là `SPL:abcd…wxyz`.** Danh sách token không xác nhận mint đó, nên Sure không đặt tên hay định giá. Bạn vẫn có thể chọn để theo dõi số lượng.

**Các khoản chuyển có giá trị 0 và bị loại khỏi tổng.** Chưa có giá cho ngày đó. Khi dữ liệu thị trường bao phủ khoảng thời gian này, lần đồng bộ tiếp theo tự chuyển các bút toán thành giao dịch đầu tư — định danh vẫn giữ nguyên nên không tạo trùng. Nếu chúng vẫn bằng không, ngày giao dịch nằm ngoài khoảng nhà cung cấp dữ liệu thị trường có thể phục vụ.

**Manage wallets báo lịch sử chưa đầy đủ.** Địa chỉ có nhiều khoản chuyển hơn lượng một lần đồng bộ đọc được. Số dư không bị ảnh hưởng. Tăng `ONCHAIN_HISTORY_MAX_PAGES` nếu cần toàn bộ lịch sử và có thể chịu thêm số request.

**Số dư đúng nhưng không có cập nhật.** Đồng bộ chỉ ghi lại tài khoản khi blockchain thực sự thay đổi — ví không hoạt động được thiết kế để không phát sinh lượt ghi nào. Xem **Settings → Providers** để biết thời điểm đồng bộ cuối và **Settings → Debug logs** (super admin), lọc theo nhà cung cấp `onchain_wallet`, để xem lỗi đã ghi.
