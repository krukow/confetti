// TODO move this into ConfettiKit when we figure out how to link Firebase there too

import Foundation
import UIKit

import ConfettiKit

import Firebase
import FirebaseUI

import SDWebImage

extension EventViewModel {
    static fileprivate var imageCache = [String: UIImage]()
    
    func displayImage(in view: UIImageView) {
        if let cached = cachedImage {
            view.image = cached
        } else if let imageRef = imageReference {
            view.sd_setImage(with: imageRef)
        }
    }
    
    var cachedImage: UIImage? {
        guard let uuid = event.person.photoUUID else { return nil }
        return EventViewModel.imageCache[uuid]
    }
    
    var imageReference: StorageReference? {
        guard let uuid = event.person.photoUUID else { return nil }
        return imagesNode.child(uuid)
    }
    
    fileprivate var imagesNode: StorageReference {
        return Storage.storage().reference().child("images")
    }
    
    func saveImage(_ image: UIImage) {
        let data = UIImageJPEGRepresentation(image, 0.5)!
        saveImage(data: data)
    }

    func clearImage() {
        if (event.person.photoUUID != nil) {
            EventViewModel.imageCache[event.person.photoUUID!] = nil
        }
        event = event.with(person: event.person.withoutImage())
        UserViewModel.current.updateEvent(event)
    }

    func saveImage(data: Data) {
        let uuid = UUID().uuidString // we always allocate a new image, rather than replacing
        let imageRef = imagesNode.child(uuid)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let modifiedPerson = event.person.with(photoUUID: uuid)
        event = event.with(person: modifiedPerson)
        
        EventViewModel.imageCache[uuid] = UIImage(data: data)!
        UserViewModel.current.updateEvent(event)
        
        let _ = imageRef.putData(data, metadata: metadata) { (metadata, error) in
            if let _ = error {
                // ...
            } else {
                EventViewModel.imageCache.removeValue(forKey: uuid)
            }
        }
    }
}
