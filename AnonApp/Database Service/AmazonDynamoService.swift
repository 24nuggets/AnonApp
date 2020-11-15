//
//  File.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 11/12/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation
import AWSDynamoDB

class DynamoService: NSObject {

    
    let db = AWSDynamoDB.default()
    
    static let sharedInstance = DynamoService()
    
    func loadPollData(key:String, uid:String, completion: @escaping ([Double], Int, String)->()){
       let pollItemInput = AWSDynamoDBGetItemInput()
        pollItemInput?.tableName = "Polls"
        let hashValue = AWSDynamoDBAttributeValue()
        hashValue?.s = key
        pollItemInput?.key = ["crackID": hashValue!]
        pollItemInput?.attributesToGet = [uid, "count1", "count2", "count3", "count4"]
        var scores:[Double] = []
        var userSelection = 0
        
        db.getItem(pollItemInput!) { (results, error) in
            if error != nil{
                print(error)
                return
            }
            let item = results?.item
            if let score = item?["count1"]?.n{
                if let scoreNum = Double(score){
                scores.append(scoreNum)
                }
            }
            if let score = item?["count2"]?.n{
                if let scoreNum = Double(score){
                scores.append(scoreNum)
                }
            }
            if let score = item?["count3"]?.n{
                if let scoreNum = Double(score){
                scores.append(scoreNum)
                }
            }
            if let score = item?["count4"]?.n{
                if let scoreNum = Double(score){
                scores.append(scoreNum)
                }
            }
            if let selection = item?[uid]?.n{
                if let selectionInt = Int(selection){
                userSelection = selectionInt
                }
            }
            completion(scores,userSelection,key)
        }
        
    }
    
    func addUserVote(key:String,uid:String, vote:Int){
        let update = AWSDynamoDBUpdateItemInput()
        update?.tableName = "Polls"
        let hashValue = AWSDynamoDBAttributeValue()
        hashValue?.s = key
        update?.key = ["crackID" : hashValue!]
        update?.updateExpression = "SET \(uid) = :vote, count\(vote) = count\(vote) + :increment"
        let voteValue = AWSDynamoDBAttributeValue()
        voteValue?.n = String(vote)
        
        let increment = AWSDynamoDBAttributeValue()
        increment?.n = "1"
        update?.expressionAttributeValues = [":increment" : increment!,
                                             ":vote" : voteValue!]
        
        
        db.updateItem(update!) { (output, error) in
            if error != nil{
                print(error)
            }
        }
        
    }
    
    
}
