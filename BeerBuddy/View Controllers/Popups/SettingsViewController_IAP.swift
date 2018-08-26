//
//  SettingsViewController_IAP.swift
//  Good Spirits
//
//  Created by Alexei Baboulevitch on 2018-8-26.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import StoreKit

extension SettingsViewController: SKProductsRequestDelegate, SKPaymentTransactionObserver
{
    func requestProducts()
    {
        if self.products != nil {
            // already have products
            return
        }
        
        if self.productsRequest == nil
        {
            appDebug("IAP requesting products...")
            let productsRequest = SKProductsRequest(productIdentifiers: [ Constants.tipIAPProductID ])
            productsRequest.delegate = self
            self.productsRequest = productsRequest
            productsRequest.start()
        }
    }
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)
    {
        self.productsRequest = nil
        self.products = response.products
        
        appDebug("IAP products retrieved!")
        
        for invalidID in response.invalidProductIdentifiers
        {
            appError("found invalid product ID in \(invalidID)")
            return
        }
        
        reloadCells: do
        {
            let iap = sectionCounts.firstIndex { $0.0 == .iap }!
            let meta = sectionCounts.firstIndex { $0.0 == .meta }!
            tableView.reloadRows(at: [IndexPath.init(row: 2, section: meta)], with: .none)
            updateFooter(tableView.footerView(forSection: iap), forSection: iap)
        }
        
        //if self.waitingToPurchase, self.products?.first != nil
        //{
        //    self.waitingToPurchase = false
        //    purchase() //should go through this time
        //}
    }
    
    func purchase()
    {
        if let product = self.products?.first
        {
            let payment = SKMutablePayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
    {
        appDebug("IAP updated transactions: \(transactions)")
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                appDebug("purchasing...")
                break
            case .purchased:
                appDebug("purchased!")
                queue.finishTransaction(transaction)
                break
            case .failed:
                print("failed!")
                appAlert("This transaction has failed: \((transaction.error!).localizedDescription)", self)
                //                if let error = transaction.error as? NSError, error.code == 0 {
                //                    self.delegate?.iapDidRequestAlert(iap: self, withTitle: "No Connection", message: "Can't connect to the iTunes Store. Are you sure you're on a data network?")
                //                }
                queue.finishTransaction(transaction)
                break
            case .deferred:
                print("deferred")
                //self.delegate?.iapDidRequestAlert(iap: self, withTitle: "Deferred", message: "Your purchase is waiting to be approved.")
                break
            case .restored:
                queue.finishTransaction(transaction)
                break
            }
        }
    }
    
    func localizedPrice() -> String?
    {
        if let product = self.products?.first
        {
            let formatter = NumberFormatter()
            formatter.formatterBehavior = .behavior10_4
            formatter.numberStyle = .currency
            formatter.locale = product.priceLocale
            
            return formatter.string(from: product.price)
        }
        else
        {
            return nil
        }
    }
}
