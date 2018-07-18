//
//  FirstViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        guard let jsonPath = Bundle.main.url(forResource: "stub", withExtension: "json") else
        {
            assert(false, "JSON file not found")
        }
        
        guard let dataImpl = DataImpl_JSON.init(withURL: jsonPath) else
        {
            assert(false, "JSON file not found")
        }
        
        let data = Data.init(impl: dataImpl)
        
        do
        {
            let checkins = try data.checkins(from: Date.distantPast, to: Date.distantFuture)
            dump(checkins)
        }
        catch
        {
            assert(false, "Error: \(error)")
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}
