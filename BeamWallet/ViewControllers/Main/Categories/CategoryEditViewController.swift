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

    @IBOutlet private weak var nameField: BMClearField!
    @IBOutlet private weak var titleNameLabel: UILabel!
    @IBOutlet private weak var titleColourLabel: UILabel!

    @IBOutlet private var colorsView: BMCategoryColorsView!

    private var category:BMCategory!
    private let colors = [UIColor.init(hexString: "#ff746b"), UIColor.init(hexString: "#ffba55"), UIColor.init(hexString: "#fee65a"), UIColor.init(hexString: "#73ff7c"), UIColor.init(hexString: "#4fa5ff"), UIColor.init(hexString: "#d785ff")]
    private let names = ["#ff746b":"Red", "#ffba55":"Orange", "#fee65a":"Yellow",
                         "#73ff7c":"Green", "#4fa5ff":"Blue", "#d785ff":"Pink"]
    
    private var selectedColor:String! {
        didSet {
            nameField.placeholder = names[selectedColor]
            nameField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        }
    }
    
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
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        hideKeyboardWhenTappedAround()

        title = category.id == 0 ? Localizable.shared.strings.new_category : Localizable.shared.strings.edit_category
        
        addRightButton(title:Localizable.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)
        
        titleNameLabel.text = Localizable.shared.strings.name.uppercased()
        titleNameLabel.letterSpacing = 1.2
        
        titleColourLabel.text = Localizable.shared.strings.colour.uppercased()
        titleColourLabel.letterSpacing = 1.2
        
        nameField.placeholder = names[selectedColor]
        nameField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        nameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        nameField.text = category.name

        colorsView = BMCategoryColorsView()
        colorsView.colors = colors
        colorsView.selectedColor = UIColor.init(hexString: category.color)
        colorsView.delegate = self
        colorsView.backgroundColor = UIColor.clear
        view.addSubview(colorsView)
        
        if let constant = self.topOffset?.constant, Device.isXDevice {
            self.topOffset?.constant = constant - 20
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let offset:CGFloat = 0
        colorsView.frame = CGRect(x: (UIScreen.main.bounds.size.width - colorsView.colorsWidht())/2, y: titleColourLabel.y + titleColourLabel.h + offset , width: colorsView.colorsWidht(), height: 50)
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
                self.alert(message: Localizable.shared.strings.category_exist)
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
                
                back()
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
