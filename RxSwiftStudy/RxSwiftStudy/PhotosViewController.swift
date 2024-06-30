//
//  PhotosViewController.swift
//  RxSwiftTest
//
//  Created by 이민재 on 6/25/24.
//

import UIKit
import RxSwift
import Photos

class PhotosViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    let bag = DisposeBag()
    private let selectedPhotosSubject = PublishSubject<UIImage>()
    
    private lazy var photos = PhotosViewController.loadPhotos()
    private lazy var imageManager = PHCachingImageManager()
    private lazy var thumbnailSize: CGSize = {
        let cellSize = (self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        return CGSize(width: cellSize.width * UIScreen.main.scale,
                      height: cellSize.height * UIScreen.main.scale)
    }()
    
    static func loadPhotos() -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return PHAsset.fetchAssets(with: allPhotosOptions)
    }
    var selectedPhotos: Observable<UIImage> {
        return selectedPhotosSubject.asObservable()
    }
    let authorized = PHPhotoLibrary.authorized
        .share()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorized
            .skip(1)
            .takeLast(1)
            .filter({ $0 == false})
            .subscribe(onNext: { [weak self] _ in
                guard let errorMessage = self?.errorMessage else { return }
                
                DispatchQueue.main.async(execute: errorMessage)
            })
            .disposed(by: bag)
        authorized
            .skip(while: { $0 == false})
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.photos = PhotosViewController.loadPhotos()
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            })
            .disposed(by: bag)
    }
    override func viewWillDisappear(_ animated: Bool) {
        selectedPhotosSubject.onCompleted()
    }
    private func errorMessage() {
        alert(title: "No access to Camero Roll", text: "You can grant access to Combinestagram from the Settings app")
            .asObservable()
            .take(for: RxTimeInterval.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
    }
}

extension PhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = photos.object(at: indexPath.row)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            }
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 80)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photos.object(at: indexPath.item)
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
            cell.flash()
        }
        
        imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] image, info in
            guard let image = image, let info = info else { return }
            
            if let isThumbnail = info[PHImageResultIsDegradedKey as NSString] as? Bool, !isThumbnail {
                print("PVC selectedPhotosSubject onNext")
                self?.selectedPhotosSubject.onNext(image)
            }
        })
    }
}
