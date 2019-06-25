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
    private let colors = [UIColor.init(hexString: "#ff746b"), UIColor.init(hexString: "#ffba55"), UIColor.init(hexString: "#fee65a"), UIColor.init(hexString: "#73ff7c"), UIColor.init(hexString: "#4fa5ff"), UIColor.init(hexString: "#d785ff")]
    
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
            self.category.name = String.empty()
            self.category.id = 0
            self.category.color = self.selectedColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizables.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isGradient {
            var mainColor = UIColor.main.brightSkyBlue
            
            if let viewControllers = self.navigationController?.viewControllers{
                for vc in viewControllers {
                    if vc is SendViewController {
                        mainColor = UIColor.main.heliotrope
                    }
                }
            }
            
            setGradientTopBar(mainColor: mainColor, addedStatusView: false)
        }
        
        hideKeyboardWhenTappedAround()

        title = category.id == 0 ? Localizables.shared.strings.new_category : Localizables.shared.strings.edit_category
        
        addRightButton(title:Localizables.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)
        
        nameView = UIView(frame: CGRect(x: 0, y: (Device.isXDevice ? 100 : 70) + 20, width: UIScreen.main.bounds.size.width, height: 49))
        if isGradient {
            nameView.y = (Device.isXDevice ? 100 : 70) + 60
        }
        nameView.backgroundColor = UIColor.main.marineTwo
        view.addSubview(nameView)
        
        nameField = UITextField(frame: CGRect(x: defaultX, y: 0, width: defaultWidth, height: 49))
        nameField.placeholder = Localizables.shared.strings.category_name
        nameField.placeHolderColor = UIColor.main.steelGrey
        nameField.textColor = UIColor.white
        nameField.font = RegularFont(size: 16)
        nameField.tintColor = UIColor.white
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        nameField.backgroundColor = UIColor.clear
        nameField.autocorrectionType = .no
        nameField.spellCheckingType = .no
        nameField.text = category.name
        nameView.addSubview(nameField)
        
        colorsView = BMCategoryColorsView()
        colorsView.colors = colors
        colorsView.selectedColor = UIColor.init(hexString: category.color)
        colorsView.delegate = self
        colorsView.frame = CGRect(x: (UIScreen.main.bounds.size.width - colorsView.colorsWidht())/2, y: nameView.frame.origin.y + nameView.frame.size.height + 20, width: colorsView.colorsWidht(), height: 50)
        colorsView.backgroundColor = UIColor.clear
        view.addSubview(colorsView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            let trimmedString = name.trimmingCharacters(in: .whitespacesAndNewlines)

            enableRightButton(enabled: self.canSave(name: trimmedString, color: selectedColor))
        }
    }
    
    @objc private func onSave() {

        if let name = nameField.text {
            let trimmedString = name.trimmingCharacters(in: .whitespacesAndNewlines)

            if AppModel.sharedManager().isNameAlreadyExist(trimmedString, id: category.id) {
                self.alert(message: Localizables.shared.strings.category_exist)
            }
            else{
                category.name = trimmedString
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
