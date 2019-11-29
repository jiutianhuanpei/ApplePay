# ApplePay


部分 API 介绍：

#### 1、 权限判断

| API | 描述 |
| --- | --- |
| open class func canMakePayments() -> Bool | 判断设备是否支持 ApplePay |
| open class func canMakePayments(usingNetworks supportedNetworks: [PKPaymentNetwork]) -> Bool | 判断设备是否支持传入的网络的 ApplePay，如果 ApplePay 里没有支持的卡，或者没有卡也会返回 false |

<br>

#### 2、 跳转钱包，设置银行卡，直接跳转到苹果的钱包应用，并唤起添加卡片页面


```swift
let wallet = PKPassLibrary()
wallet.openPaymentSetup()
```

<br>

#### 3、设置商品信息，并唤起 ApplePay 支付页面

伪代码如下，注意要点都写在 **注释** 内


```swift
let request = PKPaymentRequest()

//国家
request.countryCode = "CN"
//币种
request.currencyCode = "CNY"
//支持的网络
var networks: [PKPaymentNetwork] = [.privateLabel]
if #available(iOS 11.2, *) {
    networks.insert(.chinaUnionPay, at: 0)
}
request.supportedNetworks = networks
//商业标识符
request.merchantIdentifier = "merchant.com.cmcc.hejiakanhuDevcc"
//capability3DS 必须添加，在大陆 capabilityEMV 也必须添加，否则 didAuthorizePayment 方法不会调用
request.merchantCapabilities = [.capability3DS, .capabilityEMV, .capabilityCredit, .capabilityDebit]

//快递
let ship1 = PKShippingMethod(label: "顺丰", amount: .init(value: 10))
ship1.detail = "24小时送达"
ship1.identifier = "shunfeng"

let ship2 = PKShippingMethod(label: "韵达", amount: .init(value: 15))
ship2.detail = "隔天送达"
ship2.identifier = "yunda"

//快递列表
request.shippingMethods = [ship1, ship2]

//送货方式
request.shippingType = .shipping


//商品列表
let firstGoods = PKPaymentSummaryItem(label: "火锅", amount: .init(value: 0.00))
let secondGoods = PKPaymentSummaryItem(label: "青菜", amount: .init(value: 0.00))

paymentList = [firstGoods, secondGoods]

let list = showSummaryItems(with: ship1)

//添加商品列表，最后一个是总计
request.paymentSummaryItems = list

//商品附加信息，会被传到生成的 PKPaymentToken 中，可用于平台的校验
request.applicationData = "goodsId=123456".data(using: .utf8)

let payment = PKPaymentAuthorizationController(paymentRequest: request)
payment.delegate = self
payment.present(completion: nil)
```

<br>

#### 4、回调处理

##### 4.1 完成回调（取消支付、支付完成、失败都会调用）

```swift
func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
	//隐藏支付页面
    controller.dismiss(completion: nil)
}
```

##### 4.2 认证回调

```swift
func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
    
    //延时，模拟平台校验订单并且对接金融机构扣款
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        [unowned self] in
        
        let ret = arc4random_uniform(4) % 2 == 0
        
        if ret {
            completion(.init(status: .success, errors: nil))
            self.lbl.text = "支付成功"
        } else {
            completion(.init(status: .failure, errors: nil))
            self.lbl.text = "支付失败"
        }
    }
}
```

##### 4.3 切换送货方式回调

```swift
func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didSelectShippingMethod shippingMethod: PKShippingMethod, handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
    
    let update = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: showSummaryItems(with: shippingMethod))
    completion(update)
}
```