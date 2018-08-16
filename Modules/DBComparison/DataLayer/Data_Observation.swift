//
//  Data_Observation.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-15.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public protocol DataObservationProtocol
{
    static var DataDidChangeNotification: Notification.Name { get }
}
