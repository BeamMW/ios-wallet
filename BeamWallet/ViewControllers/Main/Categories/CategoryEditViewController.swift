//
// CategoryEditViewController.swift
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


import UIKit

class CategoryEditViewController: BaseViewController {

    public var completion : ((BMCategory?) -> Void)?

    @IBOutlet private var nameField: UITextField!
    @IBOutlet private var nameView: UIView!
    
    @IBOutlet private var colorsView: BMCategoryColorsView!

    private var category:BMCategory!
    private let colors = [UIColor.init(hexString: "#ff746b"), UIColor.init(hexString: "#ffba55"),
                           UIColor.init(hexString: "#fee65a"), UIColor.init(hexString: "#73ff7c"),
                           UIColor.init(hexString: "#4fa5ff"), UIColor.init(hexString: "#d785ff")]
    
    private var selectedColor:String!
    
    init(category:BMCategory?) {
        super.init(nibName: nil, bundle: nil)
        
        if category != nil {
            self.category = category
            
            self.selectedColor = self.category.color
        }
        else{
            self.selectedColor = self.colors.randomElement()?.toHexString()
            
            self.category = BMCategory()
            self.category.name = ""
            self.category.id = 0
            self.category.color = self.selectedColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()

        if self.navigationController is BMGradientNavigationController {
            largeTitle = category.id == 0 ? "New category".uppercased() : "Edit Category".uppercased()

            navigationItem.hidesBackButton = true
        }
        else{
            title = category.id == 0 ? "New category" : "Edit Category"

            addRightButton(title:"Save", targer: self, selector: #selector(onSave), enabled: false)
        }
        
        nameView = UIView(frame: CGRect(x: 0, y: (isNavigationGradient ? 200 : 20), width: UIScreen.main.bounds.size.width, height: 49))
        nameView.backgroundColor = UIColor.main.marineTwo
        view.addSubview(nameView)
        
        nameField = UITextField(frame: CGRect(x: 15, y: 0, width: UIScreen.main.bounds.size.width-30, height: 49))
        nameField.placeholder = "Category name"
        nameField.placeHolderColor = UIColor.main.steelGrey
        nameField.textColor = UIColor.white
        nameField.font = RegularFont(size: 16)
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        nameField.backgroundColor = UIColor.clear
        nameField.text = category.name
        nameView.addSubview(nameField)
        
        colorsView = BMCategoryColorsView()
        colorsView.colors = colors
        colorsView.selectedColor = UIColor.init(hexString: category.color)
        colorsView.delegate = self
        colorsView.frame = CGRect(x: (UIScreen.main.bounds.size.width - colorsView.colorsWidht())/2, y: nameView.frame.origin.y + nameView.frame.size.height + 20, width: colorsView.colorsWidht(), height: 51)
        view.addSubview(colorsView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isNavigationGradient {
            addRightButton(title:"Save", targer: self, selector: #selector(onSave), enabled: false)
        }
    }
    
    private func canSave(name:String, color:String) -> Bool {
        if name.isEmpty {
            return false
        }
        else if(name != category.name || color != category.color) {
            return true
        }
        else{
            return false
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let name = nameField.text {
            enableRightButton(enabled: self.canSave(name: name, color: selectedColor))
        }
    }
    
    @objc private func onSave() {
        if let name = nameField.text {
            
            if AppModel.sharedManager().isNameAlreadyExist(name, id: category.id) {
                self.alert(message: "This category name already exists")
            }
            else{
                category.name = name
                category.color = selectedColor
                
                if category.id == 0 {
                    category.id = Int32(Int.random(in: 1 ... 10024))
                    
                    AppModel.sharedManager().addCategory(category)
                }
                else{
                    AppModel.sharedManager().editCategory(category)
                }
                
                self.completion?(category)
                
                navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension CategoryEditViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}

extension CategoryEditViewController: BMColorViewDelegate {
    func onSelectColor(color: UIColor) {
        
        self.selectedColor = color.toHexString()
        self.colorsView.selectedColor = UIColor.init(hexString: self.selectedColor)
        
        if let name = self.nameField.text {
            enableRightButton(enabled: self.canSave(name: name, color: self.selectedColor))
        }
    }
}
