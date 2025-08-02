import UIKit

class DogsTableViewController: UITableViewController {
    let dogs = ["Buddy", "Bella", "Charlie", "Lucy", "Max", "Daisy"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Dogs"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dogs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DogCell") ?? UITableViewCell(style: .default, reuseIdentifier: "DogCell")
        cell.textLabel?.text = dogs[indexPath.row]
        return cell
    }
} 