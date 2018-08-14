//
//  IntroVC.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 28/06/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit

class IntroVC: UIViewController {

    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var imgIntro: UIImageView!
    @IBOutlet var btnNext: UIButton!
    @IBOutlet var btnSkip: UIButton!
    @IBOutlet var pageControl: UIPageControl!
    
    @IBOutlet weak var introImgHeightCons: NSLayoutConstraint!
    
    @IBOutlet weak var introImgWidthCons: NSLayoutConstraint!
    
    var appDel = UIApplication.shared.delegate as! AppDelegate

    
    let arrTitle = ["WHERE DO YOU WANT TO GO?","WHAT IS INTERESTING THERE?","DO YOU WANT TO GET OFF THE TOUR?"]
    
    let arrDesc = ["Take the virtual tour of Valley Transportation Authority","Pause the navigation any moment to know more about the intersting places around","When you are getting closer to a Stop, you can get off the tour and see the places nearby"]
    
    let arrImages = ["0.png","1.png","2.png"]
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let strImgName = arrImages[0] as String
        
        imgIntro.image = UIImage(named: String(describing: strImgName))
        
        lblTitle.text = arrTitle[0] as String
        lblDescription.text = arrDesc[0] as String
        
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 960:
                lblDescription.font = UIFont.systemFont(ofSize: 15.0)
                introImgWidthCons.constant = 180
                introImgHeightCons.constant = 180
                self.view.layoutIfNeeded()
            
            default: break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pageControl(_ sender: Any)
    {
        let strImgName = arrImages[pageControl.currentPage] as String
        imgIntro.image = UIImage(named: String(describing: strImgName))
        lblTitle.text = arrTitle[pageControl.currentPage] as String
        lblDescription.text = arrDesc[pageControl.currentPage] as String
        if pageControl.currentPage == 2
        {
            btnNext.setTitle("Done", for: .normal)
        }
        else
        {
            btnNext.setTitle("Next", for: .normal)
        }
    }
    @IBAction func btnSkip(_ sender: Any)
    {
        appDel.setAppNav()
    }
    
    @IBAction func btnNext(_ sender: Any)
    {
        pageControl.currentPage = pageControl.currentPage + 1
        
        let strImgName = arrImages[pageControl.currentPage] as String
        imgIntro.image = UIImage(named: String(describing: strImgName))
        lblTitle.text = arrTitle[pageControl.currentPage] as String
        lblDescription.text = arrDesc[pageControl.currentPage] as String
        
        if btnNext.titleLabel?.text == "Done"
        {
            print("done")
            
            UserDefaults.standard.set(true, forKey: "tour_end")
            UserDefaults.standard.synchronize()
            
            appDel.setAppNav()
            return
        }
        
        if pageControl.currentPage == 2
        {
            btnNext.setTitle("Done", for: .normal)
        }
        
        
        
        print(pageControl.currentPage)
    }
    
    @IBAction func onSwipeLeftGestureRecognizer(_ sender: Any) {
        pageControl.currentPage = pageControl.currentPage + 1
        
        let strImgName = arrImages[pageControl.currentPage] as String
        imgIntro.image = UIImage(named: String(describing: strImgName))
        lblTitle.text = arrTitle[pageControl.currentPage] as String
        lblDescription.text = arrDesc[pageControl.currentPage] as String
        
        if pageControl.currentPage == 2
        {
            btnNext.setTitle("Done", for: .normal)
        }
        print(pageControl.currentPage)
    }
    
    @IBAction func onSwipeRightGestureRecognizer(_ sender: UISwipeGestureRecognizer) {
        
        pageControl.currentPage = pageControl.currentPage - 1
        
        let strImgName = arrImages[pageControl.currentPage] as String
        imgIntro.image = UIImage(named: String(describing: strImgName))
        lblTitle.text = arrTitle[pageControl.currentPage] as String
        lblDescription.text = arrDesc[pageControl.currentPage] as String
        
        if pageControl.currentPage == 2
        {
            btnNext.setTitle("Done", for: .normal)
        }
        print(pageControl.currentPage)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
