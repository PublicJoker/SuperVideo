//
//  CycleModel.swift
//  PJLive
//
//  Created by Mr_Han on 2019/4/19.
//  Copyright © 2019 Mr_Han. All rights reserved.

//

import UIKit

class CycleModel: NSObject {
    /// 专辑id
    @objc var vod_id : String = ""
    /// 标题
    @objc var vod_name : String = ""
    /// 图片
    @objc var vod_pic_slide : String = ""
    
    /// 自定义构造函数
    init(dict : [String : NSObject]) {
        
        super.init()
        
        setValuesForKeys(dict)
        
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
    }

}
