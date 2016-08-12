//
//  FiltersViewController.swift
//  Yelp
//
//  Created by phil_nachum on 8/9/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

enum FilterIdentifier: String {
    case Category = "category"
    case Sort = "sort"
    case Distance = "distance"
    case Deals = "deals"
}

struct FiltersConfig {
    let deals: Bool?
    let sort: YelpSortMode?
    let distance: Double?
    let categories: [String]?
    
    init(deals: Bool? = nil, sort: YelpSortMode? = nil, distance: Double? = nil, categories: [String]? = nil) {
        self.deals = deals
        self.sort = sort
        self.distance = distance
        self.categories = categories
    }
}

protocol FiltersViewControllerDelegate {
    func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: FiltersConfig)
}

let contractedCategories = 5

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SwitchCellDelegate {

    @IBOutlet weak var tableView: UITableView!

    var categories: [[String: String]]!
    var categorySwitchStates = [Int:Bool]()
    var isDealsFilter = false
    var selectedSort: YelpSortMode?
    
    let tableStructure: [FilterIdentifier] = [.Sort, .Distance, .Deals, .Category]
    let yelpSortLabels: [String] = ["Best Match", "Distance", "Rating"]
    
    var selectedDistanceMode: YelpDistanceMode?
    var selectedDistance: Double? {
        return selectedDistanceMode == nil ? nil : distanceOptions[selectedDistanceMode!.rawValue]
    }
    // Distances are in miles
    let distanceOptions = [0.05, 0.15, 1, 5]
    let distanceLabels = ["2 blocks", "6 blocks", "1 mile", "5 miles"]
    
    var delegate: FiltersViewControllerDelegate?
    
    var expandedState: [FilterIdentifier: Bool] = [
        .Category: false,
        .Sort: false,
        .Distance: false,
        .Deals: true,
    ]

    var selectedCategories: [String] {
        return categorySwitchStates
            .filter { (row, isSelected) in isSelected }
            .map { (row, isSelected) in categories[row]["code"]! }
    }

    var filters: FiltersConfig {
        return FiltersConfig(
            deals: isDealsFilter ?? false,
            sort: selectedSort,
            distance: selectedDistance,
            categories: selectedCategories.isEmpty ? nil : selectedCategories
        )
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        categories = yelpCategories()
        tableView.allowsMultipleSelection = true

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableStructure.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableStructure[section] {
        case .Category:
            return isFilterExpanded(.Category) ? categories.count : contractedCategories
        case .Sort:
            return isFilterExpanded(.Sort) ? yelpSortLabels.count : 1
        case .Distance:
            return isFilterExpanded(.Distance) ? distanceOptions.count : 1
        case .Deals:
            return 1
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch tableStructure[indexPath.section] {
        case .Category:
            return getCategoryCell(indexPath)
        case .Sort:
            return getSortCell(indexPath)
        case .Distance:
            return getDistanceCell(indexPath)
        case .Deals:
            return getDealsCell(indexPath)
        }
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableStructure[section] {
        case .Category:
            return "Category"
        case .Sort:
            return "Sort by"
        case .Distance:
            return "Distance"
        case .Deals:
            return "Offering a Deal"
        }
    }

    func switchCell(switchCell: SwitchCell, didChangeValue value: Bool) {
        let indexPath = tableView.indexPathForCell(switchCell)!
        let section = tableStructure[indexPath.section]
        if section == .Category {
            categorySwitchStates[indexPath.row] = value
        } else if section == .Deals {
            isDealsFilter = value
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = tableStructure[indexPath.section]
        if section == .Sort {
            if isFilterExpanded(.Sort) || selectedSort == nil {
                selectedSort = YelpSortMode(rawValue: indexPath.row)
            }
        } else if section == .Distance {
            if isFilterExpanded(.Distance) || selectedDistanceMode == nil {
                selectedDistanceMode = YelpDistanceMode(rawValue: indexPath.row)
            }
        }
        
        if (section == .Sort || section == .Distance) {
            toggleSectionExpanded(section)
            tableView.reloadData()
        }
    }

    private func getCategoryCell(indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell", forIndexPath: indexPath) as! SwitchCell
        cell.switchLabel.text = categories[indexPath.row]["name"]
        cell.delegate = self
        cell.onSwitch.on = categorySwitchStates[indexPath.row] ?? false
        return cell
    }

    private func getSortCell(indexPath: NSIndexPath) -> RadioCell {
        return getSortOrDistanceCell(
            .Sort,
            indexPath: indexPath,
            options: yelpSortLabels,
            selectedIndex: selectedSort?.rawValue
        )
    }

    private func getDistanceCell(indexPath: NSIndexPath) -> RadioCell {
        return getSortOrDistanceCell(
            .Distance,
            indexPath: indexPath,
            options: distanceLabels,
            selectedIndex: selectedDistanceMode?.rawValue
        )
    }
    
    private func getSortOrDistanceCell(
        sortOrDistance: FilterIdentifier,
        indexPath: NSIndexPath,
        options: [String],
        selectedIndex: Int? ) -> RadioCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("RadioCell") as! RadioCell
        cell.accessoryType = .None
        var cellText: String
        if isFilterExpanded(sortOrDistance) {
            cellText = options[indexPath.row]
            if indexPath.row == selectedIndex {
                cell.accessoryType = .Checkmark
            }
        } else if selectedIndex == nil {
            cellText = options[0]
        } else {
            cellText = options[selectedIndex!]
            cell.accessoryType = .Checkmark
        }
        cell.radioLabel.text = cellText
        return cell
    }

    private func getDealsCell(indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell", forIndexPath: indexPath) as! SwitchCell
        cell.delegate = self
        cell.onSwitch.on = isDealsFilter
        cell.switchLabel.text = "Offering a deal"
        return cell
    }
    
    private func isFilterExpanded(section: FilterIdentifier) -> Bool {
        // Why is ! needed here?
        return expandedState[section]!
    }
    
    private func toggleSectionExpanded(section: FilterIdentifier) {
        expandedState[section] = !isFilterExpanded(section)
    }

    // MARK: - Actions

    @IBAction func onSearchButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.filtersViewController(self, didUpdateFilters: filters)
    }

    @IBAction func onCancelButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    private func yelpCategories() -> [[String: String]] {
        return [
            ["name" : "Afghan", "code": "afghani"],
            ["name" : "African", "code": "african"],
            ["name" : "American, New", "code": "newamerican"],
            ["name" : "American, Traditional", "code": "tradamerican"],
            ["name" : "Arabian", "code": "arabian"],
            ["name" : "Argentine", "code": "argentine"],
            ["name" : "Armenian", "code": "armenian"],
            ["name" : "Asian Fusion", "code": "asianfusion"],
            ["name" : "Asturian", "code": "asturian"],
            ["name" : "Australian", "code": "australian"],
            ["name" : "Austrian", "code": "austrian"],
            ["name" : "Baguettes", "code": "baguettes"],
            ["name" : "Bangladeshi", "code": "bangladeshi"],
            ["name" : "Barbeque", "code": "bbq"],
            ["name" : "Basque", "code": "basque"],
            ["name" : "Bavarian", "code": "bavarian"],
            ["name" : "Beer Garden", "code": "beergarden"],
            ["name" : "Beer Hall", "code": "beerhall"],
            ["name" : "Beisl", "code": "beisl"],
            ["name" : "Belgian", "code": "belgian"],
            ["name" : "Bistros", "code": "bistros"],
            ["name" : "Black Sea", "code": "blacksea"],
            ["name" : "Brasseries", "code": "brasseries"],
            ["name" : "Brazilian", "code": "brazilian"],
            ["name" : "Breakfast & Brunch", "code": "breakfast_brunch"],
            ["name" : "British", "code": "british"],
            ["name" : "Buffets", "code": "buffets"],
            ["name" : "Bulgarian", "code": "bulgarian"],
            ["name" : "Burgers", "code": "burgers"],
            ["name" : "Burmese", "code": "burmese"],
            ["name" : "Cafes", "code": "cafes"],
            ["name" : "Cafeteria", "code": "cafeteria"],
            ["name" : "Cajun/Creole", "code": "cajun"],
            ["name" : "Cambodian", "code": "cambodian"],
            ["name" : "Canadian", "code": "New)"],
            ["name" : "Canteen", "code": "canteen"],
            ["name" : "Caribbean", "code": "caribbean"],
            ["name" : "Catalan", "code": "catalan"],
            ["name" : "Chech", "code": "chech"],
            ["name" : "Cheesesteaks", "code": "cheesesteaks"],
            ["name" : "Chicken Shop", "code": "chickenshop"],
            ["name" : "Chicken Wings", "code": "chicken_wings"],
            ["name" : "Chilean", "code": "chilean"],
            ["name" : "Chinese", "code": "chinese"],
            ["name" : "Comfort Food", "code": "comfortfood"],
            ["name" : "Corsican", "code": "corsican"],
            ["name" : "Creperies", "code": "creperies"],
            ["name" : "Cuban", "code": "cuban"],
            ["name" : "Curry Sausage", "code": "currysausage"],
            ["name" : "Cypriot", "code": "cypriot"],
            ["name" : "Czech", "code": "czech"],
            ["name" : "Czech/Slovakian", "code": "czechslovakian"],
            ["name" : "Danish", "code": "danish"],
            ["name" : "Delis", "code": "delis"],
            ["name" : "Diners", "code": "diners"],
            ["name" : "Dumplings", "code": "dumplings"],
            ["name" : "Eastern European", "code": "eastern_european"],
            ["name" : "Ethiopian", "code": "ethiopian"],
            ["name" : "Fast Food", "code": "hotdogs"],
            ["name" : "Filipino", "code": "filipino"],
            ["name" : "Fish & Chips", "code": "fishnchips"],
            ["name" : "Fondue", "code": "fondue"],
            ["name" : "Food Court", "code": "food_court"],
            ["name" : "Food Stands", "code": "foodstands"],
            ["name" : "French", "code": "french"],
            ["name" : "French Southwest", "code": "sud_ouest"],
            ["name" : "Galician", "code": "galician"],
            ["name" : "Gastropubs", "code": "gastropubs"],
            ["name" : "Georgian", "code": "georgian"],
            ["name" : "German", "code": "german"],
            ["name" : "Giblets", "code": "giblets"],
            ["name" : "Gluten-Free", "code": "gluten_free"],
            ["name" : "Greek", "code": "greek"],
            ["name" : "Halal", "code": "halal"],
            ["name" : "Hawaiian", "code": "hawaiian"],
            ["name" : "Heuriger", "code": "heuriger"],
            ["name" : "Himalayan/Nepalese", "code": "himalayan"],
            ["name" : "Hong Kong Style Cafe", "code": "hkcafe"],
            ["name" : "Hot Dogs", "code": "hotdog"],
            ["name" : "Hot Pot", "code": "hotpot"],
            ["name" : "Hungarian", "code": "hungarian"],
            ["name" : "Iberian", "code": "iberian"],
            ["name" : "Indian", "code": "indpak"],
            ["name" : "Indonesian", "code": "indonesian"],
            ["name" : "International", "code": "international"],
            ["name" : "Irish", "code": "irish"],
            ["name" : "Island Pub", "code": "island_pub"],
            ["name" : "Israeli", "code": "israeli"],
            ["name" : "Italian", "code": "italian"],
            ["name" : "Japanese", "code": "japanese"],
            ["name" : "Jewish", "code": "jewish"],
            ["name" : "Kebab", "code": "kebab"],
            ["name" : "Korean", "code": "korean"],
            ["name" : "Kosher", "code": "kosher"],
            ["name" : "Kurdish", "code": "kurdish"],
            ["name" : "Laos", "code": "laos"],
            ["name" : "Laotian", "code": "laotian"],
            ["name" : "Latin American", "code": "latin"],
            ["name" : "Live/Raw Food", "code": "raw_food"],
            ["name" : "Lyonnais", "code": "lyonnais"],
            ["name" : "Malaysian", "code": "malaysian"],
            ["name" : "Meatballs", "code": "meatballs"],
            ["name" : "Mediterranean", "code": "mediterranean"],
            ["name" : "Mexican", "code": "mexican"],
            ["name" : "Middle Eastern", "code": "mideastern"],
            ["name" : "Milk Bars", "code": "milkbars"],
            ["name" : "Modern Australian", "code": "modern_australian"],
            ["name" : "Modern European", "code": "modern_european"],
            ["name" : "Mongolian", "code": "mongolian"],
            ["name" : "Moroccan", "code": "moroccan"],
            ["name" : "New Zealand", "code": "newzealand"],
            ["name" : "Night Food", "code": "nightfood"],
            ["name" : "Norcinerie", "code": "norcinerie"],
            ["name" : "Open Sandwiches", "code": "opensandwiches"],
            ["name" : "Oriental", "code": "oriental"],
            ["name" : "Pakistani", "code": "pakistani"],
            ["name" : "Parent Cafes", "code": "eltern_cafes"],
            ["name" : "Parma", "code": "parma"],
            ["name" : "Persian/Iranian", "code": "persian"],
            ["name" : "Peruvian", "code": "peruvian"],
            ["name" : "Pita", "code": "pita"],
            ["name" : "Pizza", "code": "pizza"],
            ["name" : "Polish", "code": "polish"],
            ["name" : "Portuguese", "code": "portuguese"],
            ["name" : "Potatoes", "code": "potatoes"],
            ["name" : "Poutineries", "code": "poutineries"],
            ["name" : "Pub Food", "code": "pubfood"],
            ["name" : "Rice", "code": "riceshop"],
            ["name" : "Romanian", "code": "romanian"],
            ["name" : "Rotisserie Chicken", "code": "rotisserie_chicken"],
            ["name" : "Rumanian", "code": "rumanian"],
            ["name" : "Russian", "code": "russian"],
            ["name" : "Salad", "code": "salad"],
            ["name" : "Sandwiches", "code": "sandwiches"],
            ["name" : "Scandinavian", "code": "scandinavian"],
            ["name" : "Scottish", "code": "scottish"],
            ["name" : "Seafood", "code": "seafood"],
            ["name" : "Serbo Croatian", "code": "serbocroatian"],
            ["name" : "Signature Cuisine", "code": "signature_cuisine"],
            ["name" : "Singaporean", "code": "singaporean"],
            ["name" : "Slovakian", "code": "slovakian"],
            ["name" : "Soul Food", "code": "soulfood"],
            ["name" : "Soup", "code": "soup"],
            ["name" : "Southern", "code": "southern"],
            ["name" : "Spanish", "code": "spanish"],
            ["name" : "Steakhouses", "code": "steak"],
            ["name" : "Sushi Bars", "code": "sushi"],
            ["name" : "Swabian", "code": "swabian"],
            ["name" : "Swedish", "code": "swedish"],
            ["name" : "Swiss Food", "code": "swissfood"],
            ["name" : "Tabernas", "code": "tabernas"],
            ["name" : "Taiwanese", "code": "taiwanese"],
            ["name" : "Tapas Bars", "code": "tapas"],
            ["name" : "Tapas/Small Plates", "code": "tapasmallplates"],
            ["name" : "Tex-Mex", "code": "tex-mex"],
            ["name" : "Thai", "code": "thai"],
            ["name" : "Traditional Norwegian", "code": "norwegian"],
            ["name" : "Traditional Swedish", "code": "traditional_swedish"],
            ["name" : "Trattorie", "code": "trattorie"],
            ["name" : "Turkish", "code": "turkish"],
            ["name" : "Ukrainian", "code": "ukrainian"],
            ["name" : "Uzbek", "code": "uzbek"],
            ["name" : "Vegan", "code": "vegan"],
            ["name" : "Vegetarian", "code": "vegetarian"],
            ["name" : "Venison", "code": "venison"],
            ["name" : "Vietnamese", "code": "vietnamese"],
            ["name" : "Wok", "code": "wok"],
            ["name" : "Wraps", "code": "wraps"],
            ["name" : "Yugoslav", "code": "yugoslav"]
        ]
    }

}
