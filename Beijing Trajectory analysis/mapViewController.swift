//
//  mapViewController.swift
//  Get all the cities
//
//  Created by LHYER on 1/26/16.
//  Copyright © 2016 D-Matrix. All rights reserved.
//
import Cocoa
import MapKit
import Foundation
import ODBCKit
class mapViewController: NSViewController,MKMapViewDelegate {
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var SQLwhere: NSTextField!
	@IBOutlet weak var progressIndicator: NSProgressIndicator!
	@IBOutlet weak var showOutlet: NSButton!
	@IBAction func show(sender: NSButton) {
		mapView.removeOverlays(mapView.overlays)
		progressIndicator.startAnimation(nil)
		showOutlet.enabled=false
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
			self.fetchData(self.SQLwhere.stringValue)
		}
		
	}
	var points=[Point]()
	var coordinates=[CLLocationCoordinate2D]()
	override func viewDidLoad() {
		super.viewDidLoad()
		mapView.mapType = .Standard
		mapView.delegate = self
		centerMapOnLocation()
		//mapView.addOverlay(MKPolyline(coordinates: &coordinates, count: coordinates.count))
	}
	override var representedObject: AnyObject? {
		didSet {
			// Update the view, if already loaded.
		}
	}
	func centerMapOnLocation() {
		let location = CLLocation(latitude: 39.9167, longitude: 116.3833)
		let regionRadius: CLLocationDistance = 4000
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,regionRadius * 2.0, regionRadius * 2.0)
		mapView.setRegion(coordinateRegion, animated: true)
	}
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		if !(annotation is Point) {
			return nil
		}
		let reuseId = "test"
		var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
		if anView == nil {
			anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
			anView!.canShowCallout = true
		}
		else {
			anView!.annotation = annotation
		}
		anView!.image = NSImage(named:"bluedot")
		return anView
	}
	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		let lineView = MKPolylineRenderer(overlay: overlay)
		lineView.strokeColor = NSColor.redColor()
		lineView.lineWidth=0.3
		return lineView
	}
	func fetchData(whereSQL: String){
		var odbcconnection: ODBCConnection;
		odbcconnection = ODBCConnection();
		odbcconnection.initSQLEnvironment();
		odbcconnection.UserName = "apple";
		odbcconnection.Password = "narutodgh";
		odbcconnection.Dsn = "mysqlmac";
		if (!odbcconnection.connect() && !odbcconnection.IsConnected){
			print("Connection Failed");
			odbcconnection.close();
			exit(0);
		}
		var rsCount:ODBCRecordset
		rsCount=odbcconnection.open("select count(*) from test1_3 "+whereSQL)
		let number:Double=Double(rsCount.fieldByIndex(0).asLong())
		dispatch_async(dispatch_get_main_queue()) {
			self.progressIndicator.maxValue=number
			self.progressIndicator.doubleValue=0.0
		}
		rsCount.close()
		
		
		
		
		
		var rs: ODBCRecordset
		//let SQL="select latitude,longitude,trackid,userid from gpsold where trackid between "+String(start+100000)+" and "+String(end+100000)+" and userid=1001;"
		let SQL="select latitude,longitude,trackid,userid from test1_3 "+whereSQL
		rs = odbcconnection.open(SQL)
		var resultss=[[CLLocationCoordinate2D]]()
		var tmpR=[CLLocationCoordinate2D]()
		var historyCoordinate=CLLocationCoordinate2D()
		var historyLocation=CLLocation()
		var historyTrackID:Int=0
		var historyUserID:Int=0
		
		
		while (!rs.isEOF()){
			if tmpR.count==0{
				historyCoordinate=CLLocationCoordinate2D(latitude: Double(rs.fieldByIndex(0).asNumber()), longitude: Double(rs.fieldByIndex(1).asNumber()))
				historyLocation=CLLocation(latitude: historyCoordinate.latitude, longitude: historyCoordinate.longitude)
				historyTrackID=Int(rs.fieldByIndex(2).asLong())
				historyUserID=Int(rs.fieldByIndex(3).asLong())
				tmpR.append(historyCoordinate)
			}else{
				let tmpCoordinate=CLLocationCoordinate2D(latitude: Double(rs.fieldByIndex(0).asNumber()), longitude: Double(rs.fieldByIndex(1).asNumber()))
				let distance=historyLocation.distanceFromLocation(CLLocation(latitude: tmpCoordinate.latitude, longitude: tmpCoordinate.longitude))
				//let TIDBool:Bool=(historyTrackID != Int(rs.fieldByIndex(2).asLong()))
				//let UIDBool:Bool=(historyUserID != Int(rs.fieldByIndex(3).asLong()))
				if distance > 500 || (historyTrackID != Int(rs.fieldByIndex(2).asLong())) || (historyUserID != Int(rs.fieldByIndex(3).asLong())) {
					//mapView.addOverlay(MKPolyline(coordinates: &tmpR, count: tmpR.count))
					//mapView.rendererForOverlay(MKPolyline(coordinates: &tmpR, count: tmpR.count))
					resultss.append(tmpR)
					tmpR.removeAll()
				}else{
					tmpR.append(tmpCoordinate)
					historyCoordinate=tmpCoordinate
					historyLocation=CLLocation(latitude: historyCoordinate.latitude, longitude: historyCoordinate.longitude)
					historyTrackID=Int(rs.fieldByName("trackid").asLong())
					historyUserID=Int(rs.fieldByName("userid").asLong())
				}
			}
			//mapView.addAnnotation(Point(coordinate: CLLocationCoordinate2D(latitude: Double(rs.fieldByName("latitude").asNumber()), longitude:Double(rs.fieldByName("longtitude").asNumber()))))
			dispatch_async(dispatch_get_main_queue()) {
				self.progressIndicator.incrementBy(1);
			}
			rs.moveNext()
		}
		resultss.append(tmpR)
		tmpR.removeAll()
		rs.close()
		odbcconnection.close()
		dispatch_async(dispatch_get_main_queue()) {
			for coord in resultss{
				var coordinates=coord
				self.mapView.addOverlay(MKPolyline(coordinates: &coordinates, count: coordinates.count))
				//coordinates.removeAll()
			}
			self.progressIndicator.stopAnimation(nil)
			let myPopup: NSAlert = NSAlert()
			myPopup.messageText="Finish Loading"
			myPopup.alertStyle=NSAlertStyle.InformationalAlertStyle
			myPopup.addButtonWithTitle("OK")
			//myPopup.runModal()
			let notification = NSUserNotification()
			notification.title = "Load Finished"
			notification.informativeText = "Doooooooooge"
			//notification.soundName = NSUserNotificationDefaultSoundName
			NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
			self.showOutlet.enabled=true
		}
		
	}
}