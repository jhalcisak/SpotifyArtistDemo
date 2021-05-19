//
//  LoginViewController.swift
//  SpotifyArtistDemo
//
//  Created by Joey Halcisak on 5/19/21.
//

import UIKit

// Cache images so they don't constantly redownload
let imageCache = NSCache<AnyObject, AnyObject>()

class SearchViewController: UITableViewController, UISearchBarDelegate {

    // Keep auth token placeholder blank until we download one
    var authToken = ""
    var searchQuery = ""
    
    @IBOutlet var searchBar: UISearchBar!
    
    struct Constants{
        static let encoded_IDSecret = "YTA0MGFlNWY1OTcxNGUyOGE5MGNjNTgwZGM0ZDIyOTA6ZjVjOTE4ZjExZWNiNDU0MWJkNDJmNjhhNWYzMTQyOTY="
    }
    
    //
    // STRUCTURE FOR PARSING JSON RESPONSE
    var result: Result?
    
    struct Result: Codable{
        let artists: Info
    }
    
    struct Info: Codable{
        let items: [Artist]
    }
    
    struct Artist: Codable {
        let name: String
        let images: [Images]
        let followers: Followers
    }
    
    struct Images: Codable{
        var url: String
    }
    
    struct Followers: Codable{
        var total: Int
    }
    
    
    // Search bar text updates (run a search)
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != ""{
            // Get a token
            // This starts the path to getting a response, because each function
            // will call the next once its completed
            getToken()
            searchQuery = searchText.replacingOccurrences(of: " ", with: "+")
        }
    }
    
    
    func getToken() {
        
        // BEGIN POST TO GET AUTH TOKEN
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        
        // SET POST HEADERS
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic " + Constants.encoded_IDSecret, forHTTPHeaderField: "Authorization")
        
        // SET POST PARAMS/BODY
        let requestParams = "grant_type=client_credentials"
        request.httpBody = requestParams.data(using: String.Encoding.utf8)
        
        // POST
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                // Check for Error
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
         
                // Retrieved data, so we will send it to be parsed
                if let data = data {
                    self.parseToken(data: data)
                }
        }
        task.resume()
    }
    
    
    // Takes data from getToken() and parses it
    func parseToken(data: Data){
        do {
            // make sure this JSON is in the format we expect
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // Sets authToken equal to the access token provided
                authToken = json["access_token"] as! String
                searchArtists(query: searchQuery)
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
    
    
    // Now that we have the access token, this function will be called
    func searchArtists(query: String) {
        
        // Make sure our auth token came through correctly and there is actually a search query
        if (authToken != "") && (query != ""){
            
            let artistUrl = URL(string: "https://api.spotify.com/v1/search?type=artist&q=" + query)!
            
            var request = URLRequest(url: artistUrl)
            request.httpMethod = "GET"
            
            // Required header
            request.setValue("Bearer " + authToken, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                // Check if Error took place
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
                
                // Read HTTP Response Status code
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200{
                        print("Response HTTP Status code: \(response.statusCode)")
                    }
                }
                
                // Everything seems okay, we returned data
                // Time to parse data
                if let data = data {
                    self.parseResults(data: data)
                }
            }
            task.resume()
            
        }
    }
    
    
    // Parses the results
    func parseResults(data: Data){
        // Automatically structures the data according to the structure we establshed above
        result = try! JSONDecoder().decode(Result.self, from: data)
        
        // Return to the main thread and refresh the tableview
        // The tableview is already waiting for objects in the result variable, so it will
        // automatically populate the data into the tableview
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if result?.artists.items.count != nil{
            return (result?.artists.items.count)!
        }
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "artistCell", for: indexPath)
        
        let nameLabel = cell.viewWithTag(1) as! UILabel
        nameLabel.text = (result?.artists.items[indexPath.row].name)!
        
        let artistImage = cell.viewWithTag(2) as! UIImageView
        if result?.artists.items[indexPath.row].images.count != 0{
            let imageLink = result?.artists.items[indexPath.row].images[0].url
            artistImage.download(urlString: imageLink! as NSString)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        passName = (result?.artists.items[indexPath.row].name)!
        if result?.artists.items[indexPath.row].images.count != 0{
            passImgLink = (result?.artists.items[indexPath.row].images[0].url)!
        }
        passFollowers = (result?.artists.items[indexPath.row].followers.total)!
        
        self.performSegue(withIdentifier: "presentArtist", sender: (Any).self)
        
    }
    


}






extension UIImageView {
    
    func download(urlString: NSString) {
        
        let url = URL(string: urlString as String)!
        
        if let cachedImage = imageCache.object(forKey: urlString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let downLoadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        
                        imageCache.setObject(downLoadedImage, forKey: urlString)
                        
                        self?.image = downLoadedImage
                    }
                }
            }
        }
    }
}
