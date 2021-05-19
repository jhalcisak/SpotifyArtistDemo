//
//  ArtistViewController.swift
//  SpotifyArtistDemo
//
//  Created by Joey Halcisak on 5/19/21.
//

import UIKit

// Establish global variables that will transfer info from search to artist page
var passName = ""
var passImgLink = ""
var passFollowers = 0

class ArtistViewController: UIViewController {

    // Outlets
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var followerLabel: UILabel!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting corresponding items with right information
        self.title = passName
        imageView.download(urlString: passImgLink as NSString)
        followerLabel.text = String(passFollowers) + "\nFollowers on Spotify"
    }

}
