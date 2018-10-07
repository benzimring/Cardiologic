//
//  Created by Adrian Mateoaea on 28/09/2016.
//  Copyright © 2016 Wonderkiln. All rights reserved.
//

import UIKit

open class WKTabBarImageLabelCell: WKTabBarImageCell {
    
    open override func set(model: WKTabBarItem) {
        super.set(model: model)
        textLabel?.text = model.title
    }
    
    override open func commonInit() {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        
        let imageView = UIImageView()
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -5).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        widthAnchorConstraint = imageView.widthAnchor.constraint(equalToConstant: imageSize)
        heightAnchorConstraint = imageView.heightAnchor.constraint(equalToConstant: imageSize)
        
        widthAnchorConstraint.isActive = true
        heightAnchorConstraint.isActive = true
        
        let textLabel = UILabel()
        textLabel.text = "Label"
        textLabel.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        textLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 15).isActive = true
        
        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        self.imageView = imageView
        self.textLabel = textLabel
    }
    
}
