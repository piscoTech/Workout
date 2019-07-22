//
//  AdsManager.swift
//  Workout Core
//
//  Created by Marco Boschi on 06/07/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary
import GoogleMobileAds
import PersonalizedAdConsent

public protocol RemoveAdsDelegate: AnyObject {
	
	/// Tells the delegate that the user purchased or restored the ad free version and ads must be hidden.
	func hideAds()
	
}

public protocol AdsManagerDelegate: RemoveAdsDelegate {
	
	var defaultPresenter: UIViewController { get }
	
	/// Tells the delegate that it can start displaying ads.
	func displayAds()
	
}

public class AdsManager: NSObject, GADBannerViewDelegate {
	
	/// Enable or disable ads override.
	private static let adsEnable = true
	
	//Ads app ID is set in the app Info.plist file
	/// Ads publisher ID
	private static let adsPublisherID = "pub-7085161342725707"
	/// Ads unit ID.
	private static let adsUnitID = "ca-app-pub-7085161342725707/5192351673"
	/// ID for InApp purchase to remove ads.
	private static let removeAdsProductId = "MarcoBoschi.ios.Workout.removeAds"
	
	private static let defaultAdRetryDelay: TimeInterval = 5.0
	private static let maxAdRetryDelay: TimeInterval = 5 * 60.0
	private var adRetryDelay: TimeInterval = 5.0
	private var allowsPersonalizedAds = true
	
	private let iapManager: InAppPurchaseManager
	
	public weak var delegate: AdsManagerDelegate? {
		didSet {
			if delegate != nil {
				// Registering here ensures that anything being received will be propagated to the delegate
				
				NotificationCenter.default.addObserver(self, selector: #selector(transactionUpdated(_:)), name: InAppPurchaseManager.transactionNotification, object: nil)
				NotificationCenter.default.addObserver(self, selector: #selector(restoreCompleted(_:)), name: InAppPurchaseManager.restoreNotification, object: nil)
			}
		}
	}
	public weak var removeAdsDelegate: RemoveAdsDelegate?
	public weak var presenter: UIViewController?
	
	/// Enabled status of ads.
	public var areAdsEnabled: Bool {
		return AdsManager.adsEnable && !iapManager.isProductPurchased(pId: Self.removeAdsProductId)
	}
	public var userCanRequestNonPersonalizedAds: Bool {
		PACConsentInformation.sharedInstance.isRequestLocationInEEAOrUnknown
	}
	
	public private(set) var adView: GADBannerView?
	
	private override init() {
		fatalError("Use the public initializer")
	}
	
	public init(preferences: Preferences) {
		self.iapManager = InAppPurchaseManager(productIds: [Self.removeAdsProductId], inUserDefaults: preferences.local)
		
		super.init()
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Initialization
	
	public func initialize() {
		guard areAdsEnabled else {
			return
		}
		
		PACConsentInformation.sharedInstance.requestConsentInfoUpdate(forPublisherIdentifiers: [Self.adsPublisherID]) { err in
			if err != nil {
				DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initialize)
				self.adRetryDelay = min(Self.maxAdRetryDelay, self.adRetryDelay * 2)
			} else {
				self.adRetryDelay = Self.defaultAdRetryDelay
				if PACConsentInformation.sharedInstance.isRequestLocationInEEAOrUnknown {
					let consent = PACConsentInformation.sharedInstance.consentStatus
					if consent == .unknown {
						DispatchQueue.main.async {
							self.collectAdsConsent(manual: false)
						}
					} else {
						self.allowsPersonalizedAds = consent == .personalized
						self.loadAds()
					}
				} else {
					self.allowsPersonalizedAds = true
					self.loadAds()
				}
			}
		}
	}
	
	// MARK: - Customization
	
	public func collectAdsConsent() {
		collectAdsConsent(manual: true)
	}
	
	private func collectAdsConsent(manual: Bool) {
		guard let privacyUrl = URL(string: "https://marcoboschi.altervista.org/app/workout/privacy/"),
			let form = PACConsentForm(applicationPrivacyPolicyURL: privacyUrl) else {
				fatalError("Incorrect privacy URL.")
		}
		
		guard let presenter = presenter ?? delegate?.defaultPresenter else {
			fatalError("No controller set to present the consent form")
		}
		
		form.shouldOfferPersonalizedAds = true
		form.shouldOfferNonPersonalizedAds = true
		form.shouldOfferAdFree = !manual && InAppPurchaseManager.canMakePayments
		
		var loading: UIAlertController?
		func displayError() {
			DispatchQueue.main.async {
				let alert = UIAlertController(simpleAlert: NSLocalizedString("MANAGE_CONSENT", comment: "Manage consent"), message: NSLocalizedString("MANAGE_CONSENT_ERR", comment: "Manage consent error"))
				
				if let l = loading {
					l.dismiss(animated: true) {
						presenter.present(alert, animated: true)
					}
				} else {
					presenter.present(alert, animated: true)
				}
			}
		}
		
		if manual {
			loading = UIAlertController.getModalLoading()
			presenter.present(loading!, animated: true)
		}
		
		form.load { err in
			if err != nil {
				if manual {
					displayError()
				} else {
					DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initialize)
					self.adRetryDelay = min(Self.maxAdRetryDelay, self.adRetryDelay * 2)
				}
			} else {
				if !manual {
					self.adRetryDelay = Self.defaultAdRetryDelay
				}
				DispatchQueue.main.async {
					func presentForm() {
						form.present(from: presenter) { err, adFree in
							if err != nil {
								if manual {
									displayError()
								} else {
									DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initialize)
									self.adRetryDelay = min(Self.maxAdRetryDelay, self.adRetryDelay * 2)
								}
							} else {
								if !manual {
									self.adRetryDelay = Self.defaultAdRetryDelay
									self.allowsPersonalizedAds = !adFree && PACConsentInformation.sharedInstance.consentStatus == .personalized
								}
								
								self.loadAds()
								if adFree {
									self.removeAds()
								}
							}
						}
					}
					
					if let l = loading {
						l.dismiss(animated: true) {
							presentForm()
						}
					} else {
						presentForm()
					}
				}
			}
		}
	}
	
	// MARK: - Displaying
	
	private func getAdRequest() -> GADRequest {
		let req = GADRequest()
		if !allowsPersonalizedAds {
			let extras = GADExtras()
			extras.additionalParameters = ["npa": "1"]
			req.register(extras)
		}
		return req
	}
	
	private func loadAds() {
		if adView == nil {
			let adView = GADBannerView(adSize: kGADAdSizeBanner)
			adView.translatesAutoresizingMaskIntoConstraints = false
			adView.rootViewController = delegate?.defaultPresenter
			adView.delegate = self
			adView.adUnitID = Self.adsUnitID
			
			self.adView = adView
		}
		adView?.load(getAdRequest())
	}
	
	public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
		guard areAdsEnabled else {
			return
		}
		
		delegate?.displayAds()
	}
	
	public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
		DispatchQueue.main.asyncAfter(delay: adRetryDelay) {
			self.adView?.load(self.getAdRequest())
			self.adRetryDelay *= 2
		}
	}
	
	// MARK: - Ad Free Version
	
	private weak var loading: UIAlertController?
	
	public func removeAds() {
		guard areAdsEnabled else {
			return
		}
		
		guard let presenter = presenter ?? delegate?.defaultPresenter else {
			fatalError("No controller set to handle the purchase process")
		}
		
		loading = UIAlertController.getModalLoading()
		presenter.present(loading!, animated: true)
		
		let buy = {
			if !self.iapManager.buyProduct(pId: Self.removeAdsProductId) {
				if let load = self.loading {
					load.dismiss(animated: true) {
						self.loading = nil
						presenter.present(InAppPurchaseManager.getProductListError(), animated: true)
					}
				} else {
					presenter.present(InAppPurchaseManager.getProductListError(), animated: true)
				}
			}
		}
		
		if !iapManager.areProductsLoaded {
			iapManager.loadProducts(completion: { (success, _) in
				if !success {
					DispatchQueue.main.async {
						if let load = self.loading {
							load.dismiss(animated: true) {
								self.loading = nil
								presenter.present(InAppPurchaseManager.getProductListError(), animated: true)
							}
						} else {
							presenter.present(InAppPurchaseManager.getProductListError(), animated: true)
						}
					}
				} else {
					buy()
				}
			})
		} else {
			buy()
		}
	}
	
	public func restorePurchase() {
		guard let presenter = presenter ?? delegate?.defaultPresenter else {
			fatalError("No controller set to handle the restoration process")
		}
		
		loading = UIAlertController.getModalLoading()
		presenter.present(loading!, animated: true, completion: nil)
		
		iapManager.restorePurchases()
	}
	
	@objc private func transactionUpdated(_ not: NSNotification) {
		guard let transaction = not.object as? TransactionStatus, transaction.product == Self.removeAdsProductId else {
			return
		}
		
		if transaction.status.isSuccess() && !areAdsEnabled {
			delegate?.hideAds()
			removeAdsDelegate?.hideAds()
		}
		
		DispatchQueue.main.async {
			guard let presenter = self.presenter ?? self.delegate?.defaultPresenter else {
				return
			}
			
			var alert: UIAlertController?
			if let err = transaction.error {
				alert = InAppPurchaseManager.getAlert(forError: err)
			} else if transaction.status == .restored {
				alert = UIAlertController(simpleAlert: NSLocalizedString("REMOVE_ADS", comment: "Ads"), message: MBLocalizedString("PURCHASE_RESTORED", comment: "Restored"))
			}
			
			if let load = self.loading {
				load.dismiss(animated: true) {
					self.loading = nil
					if let a = alert {
						presenter.present(a, animated: true)
					}
				}
			} else if let a = alert {
				presenter.present(a, animated: true)
			}
		}
	}
	
	@objc private func restoreCompleted(_ not: NSNotification) {
		guard let status = not.object as? RestorationStatus else {
			return
		}
		
		DispatchQueue.main.async {
			guard let presenter = self.presenter ?? self.delegate?.defaultPresenter else {
				return
			}
			
			if let err = status.error {
				guard let alert = InAppPurchaseManager.getAlert(forError: err) else {
					self.loading?.dismiss(animated: true) {
						self.loading = nil
					}
					
					return
				}
				
				if let load = self.loading {
					load.dismiss(animated: true) {
						self.loading = nil
						presenter.present(alert, animated: true)
					}
				} else {
					presenter.present(alert, animated: true)
				}
			} else if status.restored == 0 {
				// Nothing has been restored
				self.loading?.dismiss(animated: true) {
					self.loading = nil
				}
			}
		}
	}
	
}
