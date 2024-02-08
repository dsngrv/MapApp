//
//  MapViewController.swift
//  MapApp
//
//  Created by Дмитрий Снигирев on 06.02.2024.
//

import CoreLocation
import MapKit
import UIKit

class MapViewController: UIViewController {
    
    var trackingUserLocation = true
    var currentRoute: MKRoute?
    
    private let manager = CLLocationManager()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.mapType = .standard
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: true)
        let configuration = MKStandardMapConfiguration()
        configuration.showsTraffic = true
        mapView.preferredConfiguration = configuration
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.delegate = self
        return mapView
    }()
    
    private lazy var findUserButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 6.0
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.setImage(UIImage(systemName: "location"), for: .normal)
        button.addTarget(self, action: #selector(findUser), for: .touchUpInside)
        return button
    }()
    
    private lazy var removeAnnoButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 6.0
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.addTarget(self, action: #selector(removeAnno), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.startUpdatingLocation()
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        let longPressGetsure = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        mapView.addGestureRecognizer(longPressGetsure)
        setupLayout()
    }
    
    
    @objc func longPress(_ gr: UILongPressGestureRecognizer) {
        let point = gr.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        addAnnotation(lat: coordinate.latitude, lon: coordinate.longitude)
        createRoute(from: mapView.userLocation.coordinate, to: coordinate)
    }
    
    @objc private func removeAnno() {
        if let currentRoute = self.currentRoute {
            self.mapView.removeOverlay(currentRoute.polyline)
        }
        mapView.removeAnnotations(mapView.annotations)
    }
    
    @objc private func findUser() {
        if trackingUserLocation {
            manager.startUpdatingLocation()
            findUserButton.setImage(UIImage(systemName: "location.slash"), for: .normal)
            if let userLocation = mapView.userLocation.location {
                mapView.setCenter(userLocation.coordinate, animated: true)
            }
            trackingUserLocation = false
        } else {
            manager.stopUpdatingLocation()
            findUserButton.setImage(UIImage(systemName: "location"), for: .normal)
            trackingUserLocation = true
        }
    }
    
    private func addAnnotation(lat: Double, lon: Double) {
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        destinationAnnotation.title = "Место назначения"
        mapView.addAnnotation(destinationAnnotation)
    }
    
    private func createRoute(from startCoordinate: CLLocationCoordinate2D, to endCoordinate: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] (response, error) in
            guard let self else { return }
            
            if let error = error {
                print("Error calculating route: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {
                print("No route information available")
                return
            }
            
            // Удаляем предыдущие маршруты с карты, если они есть
            self.mapView.removeOverlays(self.mapView.overlays)
            
            // Добавляем полученные маршруты на карту
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline)
            
            // Отображаем маршрут на экране
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            
            // Записываем маршрут в переменную
            self.currentRoute = response.routes[0]
        }
    }
    
    private func setupLayout() {
        view.addSubview(mapView)
        view.addSubview(findUserButton)
        view.addSubview(removeAnnoButton)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            findUserButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            findUserButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            findUserButton.heightAnchor.constraint(equalToConstant: 40),
            findUserButton.widthAnchor.constraint(equalToConstant: 40),
            
            removeAnnoButton.topAnchor.constraint(equalTo: findUserButton.bottomAnchor, constant: 8),
            removeAnnoButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            removeAnnoButton.heightAnchor.constraint(equalToConstant: 40),
            removeAnnoButton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if trackingUserLocation {
            manager.stopUpdatingLocation()
        } else {
            manager.startUpdatingLocation()
        }
        guard let coordinate = locations.last?.coordinate else { return }
        mapView.setCenter(coordinate, animated: true)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 2.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
}
