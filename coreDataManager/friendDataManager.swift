//
//  friendDataManager.swift
//  coreDataManager
//
//  Created by Jim on 2018/7/19.
//  Copyright © 2018年 Jim. All rights reserved.
//

import UIKit

class friendDataManager: CoreDataManager<Friend> {
    
    
    static private(set) var shared: friendDataManager?
    
    func setAsSingleton(){
        friendDataManager.shared = self
    }
    
    
    
    
}
