//
//  CustomCollectionViewCell.swift
//  CollectionView Tutorial
//
//  Created by PhuongDo on 12/12/2023.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "CustomCollectionViewCell"
    
    private let customImageView: UIImageView = {
       let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.tintColor = .white
        iv.clipsToBounds = true
        return iv
    }()
    
    public func configureImage(with image: UIImage){
        self.customImageView.image = image
        self.setupUI()
    }
    
    private func setupUI(){
        self.addSubview(customImageView)
        customImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customImageView.topAnchor.constraint(equalTo: self.topAnchor),
            customImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            customImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            customImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor )
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.customImageView.image = nil
    }
    
}
