//
//  ViewController.swift
//  ApplePayDemo
//
//  Created by 沈红榜 on 2019/11/29.
//  Copyright © 2019 沈红榜. All rights reserved.
//

import UIKit
import PassKit

class ViewController: UIViewController {
    
    lazy var lbl: UILabel = {
        let l = UILabel(frame: CGRect(x: 0, y: 100, width: self.view.bounds.width, height: 40))
        l.textAlignment = .center
        l.textColor = .orange
        l.font = UIFont.systemFont(ofSize: 20)
        return l
    }()
    
    lazy var setupBtn: PKPaymentButton = {
        let btn = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        btn.center = self.view.center
        btn.addTarget(self, action: #selector(gotoWalletVC), for: .touchUpInside)
        
        return btn
    }()
    
    lazy var buyBtn: PKPaymentButton = {
        let btn = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .whiteOutline)
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        btn.center = self.view.center
        btn.addTarget(self, action: #selector(buyGoods), for: .touchUpInside)
        
        return btn
    }()
    
    var paymentList: [PKPaymentSummaryItem] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        view.addSubview(lbl)
        
        if PKPaymentAuthorizationController.canMakePayments() {
            //可以支付
            
            var networks: [PKPaymentNetwork] = [.privateLabel]
            if #available(iOS 11.2, *) {
                networks.insert(.chinaUnionPay, at: 0)
            }
            
            if PKPaymentAuthorizationController.canMakePayments(usingNetworks: networks) {
                lbl.text = "准备支付"
                //支持已定的支付渠道
                view.addSubview(buyBtn)

            } else {
                //需要绑定新卡
                lbl.text = "需要绑定新卡"
                view.addSubview(setupBtn)
            }
            
        } else {
            //不支持支付
            lbl.text = "不支付 ApplePay"
        }
    }

    @objc func gotoWalletVC() {
        let wallet = PKPassLibrary()
        wallet.openPaymentSetup()
    }
    
    @objc func buyGoods() {
        
        lbl.text = "准备支付"
        
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
    }
}



extension ViewController: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
    }
    
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
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didSelectShippingMethod shippingMethod: PKShippingMethod, handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        
        let update = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: showSummaryItems(with: shippingMethod))
        completion(update)
    }
}

extension ViewController {
    
    
    /// 根据送货方式重置商品列表
    /// - Parameter shiping: 送货方式
    func showSummaryItems(with shiping: PKShippingMethod?) -> [PKPaymentSummaryItem] {
        
        var list: [PKPaymentSummaryItem] = paymentList
        
        if let ship = shiping {
            list.append(ship)
        }
                
        var totalMoney: Float = 0.00
        
        for item in list {
            totalMoney += item.amount.floatValue
        }
        
        //添加商品列表，最后一个是总计
        let totalItem = PKPaymentSummaryItem(label: "商家", amount: .init(value: totalMoney))
        
        list.append(totalItem)
        
        return list
    }
    
}



