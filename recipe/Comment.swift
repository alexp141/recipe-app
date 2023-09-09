import Foundation

//Comments for a post on a recipe
struct Comment: Codable, Identifiable, Hashable {
    var id: String?
    //userid
    var user: String
    var datetime: String
    var content: String
    
    var dict: NSDictionary? {
        guard let id_str = id else { print("Dict not created: id value not found!"); return nil }
        return NSDictionary(dictionary:
            ["id": id_str,
             "user": user,
             "datetime": datetime,
             "content": content
            ]
        )
    }
    
    static func fromDict(_ d: NSDictionary) -> Comment? {
        guard let id = d["id"] as? String else { print("Could not parse comment id from NSDictionary"); return nil }
        guard let user = d["user"] as? String else { print("Could not parse user id from NSDicitonary"); return nil }
        guard let datetime = d["datetime"] as? String else { print("Could not parse comment datetime from NSDictionary"); return nil }
        guard let content = d["content"] as? String else { print("Could not parse comment content from NSDictionary"); return nil }
        return Comment(id: id, user: user, datetime: datetime, content: content)
    }
}
