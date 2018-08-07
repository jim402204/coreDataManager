//
//  CoreDataManager.swift
//  coreDataManager
//
//  Created by Jim on 2018/7/18.
//  Copyright © 2018年 Jim. All rights reserved.
//

import UIKit
import CoreData

typealias SaveDoneHandler = (_ success:Bool) -> Void

//不用單例  可能會存入多個資料庫
class CoreDataManager<T: NSManagedObject>: NSObject , NSFetchedResultsControllerDelegate{
    //泛型 必須繼承NSManagedObject
    
    //Constant from init().
    let momdFilename : String
    let dbFilename : String
    let dbFilePathURL : URL
    let entityName : String
    let sortKey : String
    
    private var saveDoneHandler: SaveDoneHandler?
    
   //momd編譯後的執行檔 模型檔名
    init(momdFilename: String,
         dbFilename:String? = nil,
         dbFilePathURL:URL? = nil,
         entityName: String,
         sortKey: String) {
        
        self.momdFilename = momdFilename
        if let filename = dbFilename {
            self.dbFilename = filename
        }else{
            self.dbFilename = momdFilename
        }
        
        if let url = dbFilePathURL {
            self.dbFilePathURL = url
        }else{
            // Use Document as default      //預設是放置在document  目錄下
            self.dbFilePathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        
        self.entityName = entityName
        self.sortKey = sortKey
        
        super.init()
    }
    
    // MARK: Private methods /prpperties.  彼此串再一起   managedObjectModel根源
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: momdFilename, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!  //withExtension: "momd")副檔名
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = dbFilePathURL.appendingPathComponent(dbFilename + ".sqlite")
                                                //預設資料檔的檔名
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)        //NSInMemoryStoreType 暫存 快速
        } catch {
            // Report any error we got.  下面都是錯誤捕捉
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    private lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext =            NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        //mainQueueConcurrencyType決定用什麼thread工作  coredate建議都在主執行緒用 經驗談
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    
    // MARK: - Fetched results controller
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if _fetchedResultsController != nil {       //看_fetchedResultsController在不在
            return _fetchedResultsController!       //不在就創造
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: self.managedObjectContext)   //創建
        fetchRequest.entity = entity      //丟入請求。fetchRequest某請求
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20            //預載數量
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: true)
        //NSSortDescriptor 定義 排序時 的方式           false由大到小 true小到到
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: entityName)   //sectionNameKeyPath: nil 要做成2維時 可用（最多也就2維）
        
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController as NSFetchedResultsController<NSFetchRequestResult>
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    private var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?

    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {//存檔完成式 會告述我 存檔完畢
        
        saveDoneHandler?(true)
        saveDoneHandler = nil //Important !
        
    }
    
    //Public Method/Properties.
    
    func saveContext (completion: @escaping SaveDoneHandler) {
        if managedObjectContext.hasChanges {
            do {
                //Check and keep at saveDoneHandler
                guard saveDoneHandler == nil else{
                    completion(false)
                    return
                }
                saveDoneHandler = completion
                
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }else{
            completion(true)
        }
        
    }
    
    
    var totalCount : Int{
        //table 2維                                  0 改為一維
        let sectionInfo = self.fetchedResultsController.sections![0]
        return sectionInfo.numberOfObjects
    }
    
    func createObject() -> T {

        return NSEntityDescription.insertNewObject(
            forEntityName: entityName, into: self.managedObjectContext) as! T
    }
    
    func delete(object: T) {
        self.managedObjectContext.delete(object)
    }
    //讀取
    func fetchObject(at: Int) -> T? {
        let indexPath = IndexPath(row: at, section: 0)  //最開始的位置
        
        return self.fetchedResultsController.object(at: indexPath) as? T
    }
    
    func searchBy(keyword:String , field:String) -> [T]? {//特定條件的搜尋
        
        
        let request = NSFetchRequest<T>(entityName:entityName)
        
        let predicate = NSPredicate(format: field + " CONTAINS[cd] \"\(keyword)\"")
        // ==> name CONTAINS[cd] "Lee"  主 CONTAINS包含 cd不區分大小寫 “條件名稱”
        request.predicate = predicate
        
        do{
            return try managedObjectContext.fetch(request)
        }catch{
            assertionFailure("Fail to fetch: \(error)")
        }
        
        return nil
    }
    
    
}
