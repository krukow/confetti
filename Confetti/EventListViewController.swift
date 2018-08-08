import UIKit
import ConfettiKit
import AppCenterAnalytics

import Firebase

extension UIViewController {
    func styleTransparentNavigationBar() {
        // Get rid of nav bar shadow for a nice, continuous look
        guard let bar = navigationController?.navigationBar else { return }
        
        bar.shadowImage = UIImage()
        bar.setBackgroundImage(UIImage(), for: .default)
        bar.isTranslucent = true
    }
}

class EventListViewController: UITableViewController, HeroStretchable {
    
    @IBOutlet var heroView: HeroView!
    @IBOutlet var footerView: UIView!
    @IBOutlet var emptyTableView: UIView!
    
    var launchEventKey: String?
    
    var viewModels = [EventViewModel]() {
        didSet {
            viewModelsWithoutHero = [EventViewModel](viewModels.dropFirst())
        }
    }
    
    private var viewModelsWithoutHero = [EventViewModel]()
    
    var registrations = [NotificationRegistration]()
    var notificationInfo = [AnyHashable : Any]()
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleTransparentNavigationBar()
        setupStretchyHero()
        
        // Remove the label from back button in nav bar
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "  ", style: .plain, target: nil, action: nil)
        
        let onEventsChanged = UserViewModel.current.onEventsChanged {
            self.updateWith(events: $0)
        }
        
        UserViewModel.current.performMigrations()
        
        registrations.append(onEventsChanged)
        
        heroView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(heroTapped(_:))))
    }
    
    @objc func heroTapped(_ sender: Any) {
        guard let controller: EventDetailViewController = viewController("eventDetail") else {
            return
        }
        controller.event = viewModels.first
        navigationController?.pushViewController(controller, animated: true)
        MSAnalytics.trackEvent("viewDetails", withProperties: ["type": controller.event.event.occasion.kind.rawValue]);
    }
    
    func displayEvent(withKey key: String) {
        tabBarController?.selectedIndex = 0
        guard let details: EventDetailViewController = viewController("eventDetail") else { return }
        guard let event = viewModels.first(where: { $0.event.key == key }) else { return }
        details.event = event
        navigationController?.pushViewController(details, animated: false)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateStretchyHero()
    }
    
    deinit {
        registrations.forEach { $0.removeObserver() }
    }
    
    func updateWith(events: [Event]) {
        viewModels = events
                        .map { EventViewModel.fromEvent($0) }
                        .sorted(by: { $0.daysAway < $1.daysAway })
        if let hero = viewModels.first {            
            heroView.runMode = .event(hero)
        }
        
        if viewModels.count == 0 {
            tableView.backgroundView = emptyTableView
            heroView.isHidden = true
            footerView.isHidden = true
        } else {
            tableView.backgroundView = nil
            heroView.isHidden = false
            footerView.isHidden = false            
            tableView.reloadData()
        }
        
        if let key = launchEventKey {
            launchEventKey = nil
            displayEvent(withKey: key)
        }
    }
    
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case "showDetail":
            let controller = segue.destination as! EventDetailViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                controller.event = viewModelsWithoutHero[indexPath.row]
            }
        default:
            return
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModelsWithoutHero.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! EventTableViewCell
        
        // Rasterize cells to improve scrolling performance, since they don't change and contain large images
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        let event = viewModelsWithoutHero[indexPath.row]
        cell.setEvent(event)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(EventTableViewCell.defaultHeight);
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let viewModel = viewModelsWithoutHero[indexPath.row]
            UserViewModel.current.deleteEvent(viewModel.event)
        default:
            return
        }
    }
}

