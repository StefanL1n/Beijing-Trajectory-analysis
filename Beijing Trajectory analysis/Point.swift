//
//  Shit.swift
//  Get all the cities
//
//  Created by LHYER on 1/26/16.
//  Copyright © 2016 D-Matrix. All rights reserved.
//
import Foundation
import MapKit
class Point: NSObject, MKAnnotation {
	let title:String?
	let coordinate: CLLocationCoordinate2D
	let subtitle:String?
	init(coordinate: CLLocationCoordinate2D) {
		self.title = String(coordinate.latitude)
		self.coordinate = coordinate
		self.subtitle=String(coordinate.longitude)
		super.init()
	}
}