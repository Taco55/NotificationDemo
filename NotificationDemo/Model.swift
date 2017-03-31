import Foundation
import RealmSwift

class User: Object {
    public dynamic var username: String?
    public dynamic var email: String?
    public dynamic var sharedServerPath: String?
}


class Dog: Object {
    public dynamic var name: String?
    public dynamic var owner: User?
}
