//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit
import MBProgressHUD
import MapKit
import CoreLocation

class BusinessesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FiltersViewControllerDelegate, UISearchBarDelegate, UIScrollViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate {

    var businesses: [Business] = [Business]()
    var searchBar: UISearchBar!
    var filters: FiltersConfig = FiltersConfig()
    var searchPage: Int = 0
    var locationManager: CLLocationManager!

    var isMoreDataLoading = false
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar = UISearchBar()
        navigationItem.titleView = searchBar
        searchBar.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        tableView.hidden = true

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 200
        locationManager.requestWhenInUseAuthorization()

        performSearch()

/* Example of Yelp search with more search options specified
        Business.searchWithTerm("Restaurants", sort: .Distance, categories: ["asianfusion", "burgers"], deals: true) { (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses = businesses

            for business in businesses {
                print(business.name!)
                print(business.address!)
            }
        }
*/
    }

    func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: FiltersConfig) {
        self.filters = filters
        performSearch()
    }


    // MARK: - Table view


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return businesses.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusinessCell", forIndexPath: indexPath) as! BusinessCell
        cell.business = businesses[indexPath.row]
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Search bar

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        searchBar.text = ""
    }

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        searchBar.text = ""
    }

    private func performSearch() {
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        let categories = filters.categories
        let isDealsFilter = filters.deals
        let sort = filters.sort
        let distance = filters.distance
        let search = searchBar.text ?? ""
        isMoreDataLoading = true
        Business.searchWithTerm(search, sort: sort, categories: categories, deals: isDealsFilter, distance: distance, page: searchPage) { (businesses, error) in
            MBProgressHUD.hideHUDForView(self.view, animated: true)
            self.businesses.appendContentsOf(businesses)
            self.isMoreDataLoading = false

            for business in self.businesses {
                self.addBusinessAnnotation(business)
            }
            self.tableView.reloadData()
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as! UINavigationController
        let filtersViewController = navigationController.topViewController as! FiltersViewController
        filtersViewController.delegate = self
    }

    // MARK: - Scroll view

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (!isMoreDataLoading) {
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height

            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.dragging) {
                searchPage += 1
                performSearch()
            }
        }
    }

    // MARK: - Map view

    func goToLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(location.coordinate, span)
        mapView.setRegion(region, animated: false)
    }

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.1, 0.1)
            let region = MKCoordinateRegionMake(location.coordinate, span)
            mapView.setRegion(region, animated: false)
        }
    }

    func addBusinessAnnotation(business: Business) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(business.address!) {
            if let placemark = $0.0 {
                let coords = placemark[0].location!.coordinate
                self.addAnnotationAtCoordinate(coords, title: business.name ?? "Nameless business")
            }
        }
    }

    func addAnnotationAtCoordinate(coordinate: CLLocationCoordinate2D, title: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "customAnnotationView"

        // custom image annotation
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if (annotationView == nil) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView!.annotation = annotation
        }
        annotationView!.image = UIImage(named: "customAnnotationImage")

        return annotationView
    }

}
