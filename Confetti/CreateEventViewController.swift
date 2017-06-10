import UIKit
import Foundation

import ConfettiKit

import Firebase

import Contacts

import SDWebImage
import AvatarImageView

class CreateEventViewController: UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    
    @IBOutlet var photoView: AvatarImageView!
    @IBOutlet var navBarItem: UINavigationItem!
    @IBOutlet var datePicker: UIDatePicker!
    
    var createEventSpec: CreateEventSpec!
    
    var contact: Contact!
    
    var photoUrl: URL?
    
    struct AvatarConfig: AvatarImageViewConfiguration {
        var shape: Shape = .circle
    }
    
    struct AvatarData: AvatarImageViewDataSource {
        let name: String
        let avatar: UIImage?
        
        var bgColor: UIColor? {
            return Colors.accentFor(avatarId)
        }
        
        init(contact: Contact) {
            if let data = contact.imageData {
                avatar = UIImage(data: data)
            } else {
                avatar = nil
            }
            name = contact.fullName
        }
    }
    
    override func viewDidLoad() {
        photoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(choosePhoto(_:))))
    }
    
    @IBAction func updateDatePicker(_ sender: Any) {
        let birthday = datePicker.date
        let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year!
        let nextAge = NSNumber(integerLiteral: age + 1)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        let nextAgeFormatted = formatter.string(from: nextAge)
        
        navBarItem.title = contact.firstName + "'s " + nextAgeFormatted! + " birthday"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let contact = contact {
            navBarItem.title = contact.firstName + "'s Birthday"
            
            photoView.configuration = AvatarConfig()
            photoView.dataSource = AvatarData(contact: contact)
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {        
        let birthday = datePicker.date
        let month = datePicker.calendar.component(.month, from: birthday)
        let day = datePicker.calendar.component(.day, from: birthday)
        let year = datePicker.calendar.component(.year, from: birthday)
        
        let person = Person(contact.firstName, photoUrl: photoUrl?.absoluteString)
        let event = createEventSpec.createEvent(person: person, month: month, day: day, year: year)
        
        UserViewModel.current.addEvent(event)
        
        performSegue(withIdentifier: "unwindToMain", sender: self)
    }
    
    @IBAction func choosePhoto(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func upload(image: UIImage, completion: ((StorageMetadata?, Error?) -> Void)? = nil) {
        let data = UIImageJPEGRepresentation(image, 0.5)!
        
        let storage = Storage.storage()
        let imagesNode = storage.reference().child("images")
        
        let uuid = UUID.init()
        let imageRef = imagesNode.child("\(uuid.uuidString).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = imageRef.putData(data, metadata: metadata, completion: completion)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        guard let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
            
        upload(image: pickedImage) { (metadata, error) in
            guard let metadata = metadata else { return }
            self.photoUrl = metadata.downloadURL()
        }
    }
}
