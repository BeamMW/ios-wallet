//
// Localizable.shared.strings.swift
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

import Foundation

class Localizable : NSObject {
    static let shared = Localizable()

    public var strings = LocalizableStrings()
    
    public func reset() {
        strings = LocalizableStrings()        
    }
}

class LocalizableStrings : NSObject {
    
    var cancel = "cancel".localized
    var no_space_title = "no_space_title".localized
    var no_space_info = "no_space_info".localized
    var transaction_fee  = "transaction_fee".localized
    var transaction_id  = "transaction_id".localized
    var kernel_id  = "kernel_id".localized
    var comment  = "comment".localized
    var failure_reason  = "failure_reason".localized
    var cancel_transaction  = "cancel_transaction".localized
    var delete_transaction  = "delete_transaction".localized
    var repeat_transaction  = "repeat_transaction".localized
    var payment_proof  = "payment_proof".localized
    var utxo_list  = "utxo_list".localized
    var transaction_details  = "transaction_details".localized
    var new_line = "\n"
    var sender  = "sender".localized
    var receiver  = "receiver".localized
    var amount  = "amount".localized
    var beam  = "beam".localized
    var beam_2  = "beam".localized.replacingOccurrences(of: " ", with: "")

    var fatalInitCoderError = "init(coder:) has not been implemented"
    var spent  = "spent".localized
    var total  = "total".localized
    var restore_wallet_title  = "restore_wallet_title".localized.capitalizingFirstLetter()
    var id  = "id".localized
    var face_id  = "face_id".localized
    var touch_id  = "touch_id".localized
    var empty_password  = "empty_password".localized
    var incorrect_password = "incorrect_password".localized
    var create_new_wallet = "create_new_wallet".localized
    var wallet = "wallet".localized
    var transactions = "transactions".localized
    var export = "export".localized
    var activate = "activate".localized
    var activate_security_title = "activate_security_title".localized
    var activate_security_text = "activate_security_text".localized
    var change_password = "change_password".localized
    var password = "password".localized
    var old_password = "old_password".localized
    var passwords_dont_match = "passwords_dont_match".localized
    var enable = "enable".localized
    var dont_use = "dont_use".localized
    var return_to_seed_title = "return_to_seed_title".localized
    var return_to_seed_info = "return_to_seed_info".localized
    var retur = "return".localized
    var enable_face_id_title = "enable_face_id_title".localized
    var enable_touch_id_title = "enable_touch_id_title".localized
    var enable_face_id_text = "enable_face_id_text".localized
    var enable_touch_id_text = "enable_touch_id_text".localized
    var zero = "0"
    var restoring_wallet = "restoring_wallet".localized
    var restored = "restored".localized
    var loading_wallet = "loading_wallet".localized
    var no_internet = "no_internet".localized
    var error = "error".localized
    var wallet_not_created = "wallet_not_created".localized
    var wallet_not_opened = "wallet_not_opened".localized
    var external_link_title = "external_link_title".localized
    var external_link_text = "external_link_text".localized
    var open = "open".localized
    var addresses = "addresses".localized
    var utxo = "utxo".localized
    var settings = "settings".localized
    var details = "details".localized
    var utxo_type = "utxo_type".localized
    var all = "all".localized
    var save_seed_title = "save_seed_title".localized
    var save_seed_info = "save_seed_info".localized
    var done = "done".localized
    var copied_to_clipboard = "copied_to_clipboard".localized
    var seed_capture_warning = "seed_capture_warning".localized
    var seed_prhase = "seed_prhase".localized
    var confirm_seed = "confirm_seed".localized
    var seed_back_title = "seed_back_title".localized
    var seed_back_text = "seed_back_text".localized
    var generate = "generate".localized
    var address = "address".localized
    var exp_date = "exp_date".localized
    var show_qr_code = "show_qr_code".localized
    var copy_address = "copy_address".localized
    var edit_address = "edit_address".localized
    var delete_address = "delete_address".localized
    var delete_address_transaction = "delete_address_transaction".localized
    var delete_address_only = "delete_address_only".localized
    var in_24_hours = "in_24_hours".localized
    var in_24_hours_now = "in_24_hours_now".localized
    var transaction_history = "transaction_history".localized
    var min_fee_error = "min_fee_error".localized
    var never = "never".localized
    var save = "save".localized
    var active_address = "active_address".localized
    var expire_now = "expire_now".localized
    var open_settings = "open_settings".localized
    var camera_denied_text = "camera_denied_text".localized
    var camera_restricted = "camera_restricted".localized
    var error_scan_qr_code = "error_scan_qr_code".localized
    var scan_qr_code = "scan_qr_code".localized
    var receive = "receive".localized
    var received = "received".localized
    var delete_all_addresses = "delete_all_addresses".localized
    var delete_all_contacts = "delete_all_contacts".localized
    var delete_all_transactions = "delete_all_transactions".localized
    var clear = "clear".localized
    var clear_data = "clear_data".localized
    var contacts = "contacts".localized
    var and = "and".localized
    var rate_title = "rate_title".localized
    var rate_text = "rate_text".localized
    var rate_app = "rate_app".localized
    var feedback = "feedback".localized
    var not_now = "not_now".localized
    var ios_feedback = "iOS Feedback"
    var support_email = "support@beam.mw"
    var support_email_mailto = "mailto:support@beam.mw"
    var amount_empty = "amount_empty".localized
    var amount_zero = "amount_zero".localized
    var next = "next".localized.lowercased()
    var where_buy_beam = "where_buy_beam".localized
    var logout = "logout".localized
    var logout_text = "logout_text".localized
    var yes = "yes".localized
    var updating = "updating".localized
    var connecting = "connecting".localized
    var online = "online".localized
    var offline = "offline".localized
    var tg_bot = "tg_bot".localized
    var tg_bot_link = "tg_bot_link".localized
    var share_qr_code = "share_qr_code".localized
    var qr_code = "qr_code".localized
    var edit = "edit".localized
    var delete = "delete".localized
    var undo = "undo".localized
    var cancelled = "cancelled".localized
    var delete_transaction_title = "delete_transaction_title".localized
    var delete_transaction_text = "delete_transaction_text".localized
    var current_password_error = "current_password_error".localized
    var cancel_transaction_text = "cancel_transaction_text".localized
    var no = "no".localized
    var address_deleted = "address_deleted".localized
    var show_owner_key = "show_owner_key".localized
    var ownerkey_touchid_text = "ownerkey_touchid_text".localized
    var ownerkey_faceid_text = "ownerkey_faceid_text".localized
    var ownerkey_copied = "ownerkey_copied".localized
    var expires = "expires".localized
    var none = "none".localized
    var change_address = "change_address".localized
    var address_search = "address_search".localized
    var not_found = "not_found".localized
    var touch_id_ownerkey_verefication = "touch_id_ownerkey_verefication".localized
    var send = "send".localized
    var incorrect_address = "incorrect_address".localized
    var address_is_expired = "address_is_expired".localized
    var groth = "groth".localized
    var optional = "optional".localized
    var name = "name".localized
    var confirm = "confirm".localized
    var send_to = "send_to".localized.uppercased()
    var amount_to_send = "amount_to_send".localized
    var send_notice = "send_notice".localized    
    var save_address_title = "save_address_title".localized
    var save_address_text = "save_address_text".localized
    var not_save = "not_save".localized
    var address_copied = "address_copied".localized
    var copy = "copy".localized
    var contact = "contact".localized
    var edit_contact = "edit_contact".localized
    var delete_contact = "delete_contact".localized
    var copy_contact = "copy_contact".localized
    var delete_contact_transaction = "delete_contact_transaction".localized
    var delete_contact_only = "delete_contact_only".localized
    var outgoing = "outgoing".localized.uppercased().replacingOccurrences(of: "autogenerated".localized.uppercased(), with: "autogenerated".localized.lowercased())
    var outgoing_address = "outgoing_address".localized
    var your_password = "your_password".localized
    var node = "node".localized
    var categories = "categories".localized
    var ip_port = "ip_port".localized
    var ask_password = "ask_password".localized
    var allow_open_link = "allow_open_link".localized
    var report_problem = "report_problem".localized
    var unlock_password = "unlock_password".localized
    var contact_deleted = "contact_deleted".localized
    var autogenerated = "autogenerated".localized
    var save_edit_address_text = "save_edit_address_text".localized
    var save_changes = "save_changes".localized
    var my_rec_address = "my_rec_address".localized
    var my_send_address = "my_send_address".localized
    var my_address = "my_address".localized
    var no_name = "no_name".localized
    var you_send = "you_send".localized
    var beam_recepient_auto = "beam_recepient_auto".localized.uppercased().replacingOccurrences(of: "autogenerated".localized.uppercased(), with: "autogenerated".localized.lowercased())
    var beam_recepient = "beam_recepient".localized
    var enter_password_title = "enter_password_title".localized
    var enter_password = "enter_password".localized
    var expired = "expired".localized
    var total_available = "total_available".localized
    var receive_notice = "receive_notice".localized
    var requested_amount = "requested_amount".localized
    var now = "now".localized
    var blockchain_height = "blockchain_height".localized
    var show_utxo = "show_utxo".localized    
    var available = "available".localized
    var key_code = "key_code".localized
    var or = "or".localized
    var open_in_explorer = "open_in_explorer".localized
    var version = "version".localized
    var transaction_deleted = "transaction_deleted".localized
    var language = "language".localized
    var as_set = "as_set".localized.capitalizingFirstLetter()
    var invalid_address_title = "invalid_address_title".localized.capitalizingFirstLetter()
    var invalid_address_text = "invalid_address_text".localized
    var downloading = "downloading".localized
    var def = "default".localized
    var my_active = "my_active".localized
    var my_expired = "my_expired".localized
    var general_settings = "general_settings".localized
    var unavailable = "unavailable".localized
    var in_progress = "in_progress".localized
    var h = "h".localized
    var m = "m".localized
    var send_qr_secure = "send_qr_secure".localized
    var share_details = "share_details".localized
    var copy_details = "copy_details".localized
    var maturing = "maturing".localized
    var auth_face_confirm = "auth_face_confirm".localized
    var auth_touch_confirm = "auth_touch_confirm".localized
    var auth_bio_failed = "auth_bio_failed".localized
    var my_active_addresses = "my_active_addresses".localized
    var contacts_empty = "contacts_empty".localized
    var addresses_empty = "addresses_empty".localized
    var utxo_empty = "utxo_empty".localized
    var transactions_empty = "transactions_empty".localized
    var automatic_restore_title = "automatic_restore_title".localized.uppercased()
    var automatic_restore_text = "automatic_restore_text".localized
    var manual_restore_title = "manual_restore_title".localized.uppercased()
    var manual_restore_text = "manual_restore_text".localized
    var paste_owner_key = "paste_owner_key".localized
    var owner_key = "owner_key".localized
    var new_transaction = "new_transaction".localized
    var click_to_receive = "click_to_receive".localized
    var album = "album".localized
    var beam_title = "beam_title".localized
    var add_contact = "add_contact".localized
    var address_already_exist_1 = "address_already_exist_1".localized
    var address_already_exist_2 = "address_already_exist_2".localized
    var confirm_transaction_1 = "confirm_transaction_1".localized
    var confirm_transaction_2 = "confirm_transaction_2".localized
    var confirm_transaction_3 = "confirm_transaction_3".localized
    var transactions_list = "transactions_list".localized
    var secutiry_utxo = "secutiry_utxo".localized
    var date = "date".localized
    var downloading_blockchain = "downloading_blockchain".localized
    var restor_wallet_warning = "restor_wallet_warning".localized
    var restor_wallet_info = "restor_wallet_info".localized
    var auto_restore_warning = "auto_restore_warning".localized
    var understand = "understand".localized
    var manual_restore_warning = "manual_restore_warning".localized
    var search_transactions = "search_transactions".localized
    var random_node = "random_node".localized

    var restore_create_title = "restore_create_title".localized
    var restore_create_text = "restore_create_text".localized
    var proceed = "proceed".localized

    var addresses_empty_expired = "addresses_empty_expired".localized
    var addresses_empty_active = "addresses_empty_active".localized
    var utxo_empty_progress = "utxo_empty_progress".localized
    var transactions_empty_progress = "transactions_empty_progress".localized

    var info_restore_title = "info_restore_title".localized
    var info_restore_text = "info_restore_text".localized
    
    var crash_title = "crash_title".localized
    var crash_message = "crash_message".localized
    var crash_negative = "crash_negative".localized
    var crash_positive = "crash_positive".localized

    var estimted_time = "estimted_time".localized
    var node_address = "node_address".localized.lowercased()
    var create_new_password_short = "create_new_password_short".localized
    var create_new_password = "create_new_password".localized

    var lock_screen = "lock_screen".localized
    var paste_payment_proof = "paste_payment_proof".localized

    var show_owner_key_auth_1 = "show_owner_key_auth_1".localized
    var show_owner_key_auth_2 = "show_owner_key_auth_2".localized
    var show_owner_key_auth_3 = "show_owner_key_auth_3".localized
    var use_touch_id = "use_touch_id".localized
    var use_face_id = "use_face_id".localized
    var enter_your_password = "enter_your_password".localized
    var save_contact_title = "save_contact_title".localized

    var show_seed_phrase = "show_seed_phrase".localized
    var increase_security_text = "increase_security_text".localized
    var make_wallet_secure_text = "make_wallet_secure_text".localized
    var complete_verification = "complete_verification".localized
    var create_password = "create_password".localized
    var faucet_text = "faucet_text".localized
    var get_coins = "get_coins".localized
    var secure_your_phrase = "secure_your_phrase".localized
    var privacy = "privacy".localized
    var clear_local_data = "clear_local_data".localized
    var get_beam_faucet = "get_beam_faucet".localized
    var change_node_text_1 = "change_node_text_1".localized
    var change_node_text_2 = "change_node_text_2".localized
    var change_node_text_3 = "change_node_text_3".localized
    var change_settings_text_1 = "change_settings_text_1".localized
    var change_settings_text_2 = "change_settings_text_2".localized
    var change_settings_text_3 = "change_settings_text_3".localized
    var clear_wallet_text = "clear_wallet_text".localized
    var sent = "sent".localized
    var display_seed = "display_seed".localized
    var display_seed_old = "display_seed_old".localized
    var confirm_seed_text = "confirm_seed_text".localized
    var input_seed = "input_seed".localized
    var intro_seed_main = "intro_seed_main".localized
    var intro_seed_1 = "intro_seed_1".localized
    var intro_seed_2 = "intro_seed_2".localized
    var intro_seed_3 = "intro_seed_3".localized
    var paste = "paste".localized
    var enter_trusted_node = "enter_trusted_node".localized
    var your_current_password = "your_current_password".localized
    var clear_wallet_password = "clear_wallet_password".localized
    var remove_wallet = "remove_wallet".localized
    var export_wallet_data = "export_wallet_data".localized
    var import_wallet_data = "import_wallet_data".localized
    var utilities = "utilities".localized
    var incorrect_file_title = "incorrect_file_title".localized
    var incorrect_file_text = "incorrect_file_text".localized
    var import_data_title = "import_data_title".localized
    var import_data_text = "import_data_text".localized
    var imprt = "import".localized
    var export_data = "export_data".localized
    var delete_address_text = "delete_address_text".localized
    var delete_contact_text = "delete_contact_text".localized
    var i_will_later = "i_will_later".localized
    var import_data_text_2 = "import_data_text_2".localized
    var till_block = "till_block".localized
    var since = "till_block".localized
    var dark_mode = "dark_mode".localized
    var seed_verification = "seed_verification".localized
    var complete_seed_verification = "complete_seed_verification".localized
    var faucet_redirect_text = "faucet_redirect_text".localized
    var clear_wallet_transactions_text = "clear_wallet_transactions_text".localized
    var show_amounts_in = "show_amounts_in".localized
    var second_currency = "second_currency".localized
    var notifications = "notifications".localized
    var news = "news".localized
    var address_expiration = "address_expiration".localized
    var transaction_status = "transaction_status".localized
    var wallet_updates = "wallet_updates".localized
    var new_notifications_title = "new_notifications_title".localized
    var new_notifications_text = "new_notifications_text".localized
    var transaction = "transaction".localized
    var address_expired_notif = "address_expired_notif".localized
    var clear_all = "clear_all".localized
    var address_expired = "address_expired".localized
    var transaction_received = "transaction_received".localized
    var transaction_sent = "transaction_sent".localized
    var read = "read".localized
    var no_notifications = "no_notifications".localized
    var new_version_available_notif_title = "new_version_available_notif_title".localized
    var new_version_available_notif_detail = "new_version_available_notif_detail".localized
    var notification = "notification".localized
    var update_now = "update_now".localized
    var remaining = "remaining".localized
    var change = "change".localized
    var change_locked = "change_locked".localized
    var off = "off".localized
    var wallet_id = "wallet_id".localized
    var one_time = "one_time".localized
    var permanent = "permanent".localized
    var reconnect = "reconnect".localized.lowercased()
    var max = "max".localized
    var transaction_type = "transaction_type".localized
    var transaction_info = "transaction_info".localized
    var type = "type".localized
    var regular = "regular".localized
    var identity = "identity".localized
    var for_pool = "for_pool".localized
    var receive_notice_max_privacy = "receive_notice_max_privacy".localized
    var withdraw = "withdraw".localized
    var withdraw_cofirm = "withdraw_cofirm".localized
    var confirm_2 = "confirm_2".localized
    var sbbs_address = "sbbs_address".localized
    var address_type = "address_type".localized
    var shielded_pool = "shielded_pool".localized
    var min_fee_error_offline = "min_fee_error_offline".localized
    var maturity = "maturity".localized
    var show_public_offline = "show_public_offline".localized
    var offline_address = "offline_address".localized
    var public_offline_address_info = "public_offline_address_info".localized
    var public_offline = "public_offline".localized
    var max_privacy = "max_privacy".localized
    var tr_sent_public_offline = "tr_sent_public_offline".localized
    var tr_sent_offline = "tr_sent_offline".localized
    var tr_received_public_offline = "tr_received_public_offline".localized
    var tr_received_offline = "tr_received_offline".localized
    var address_details = "address_details".localized
    var connect_node_offline_public = "connect_node_offline_public".localized
    var send_address_placholder = "send_address_placholder".localized
    var local_comment = "local_comment".localized
    var choose_currency = "choose_currency".localized
    var max_privacy_lock_time = "max_privacy_lock_time".localized
    var lock_time_limit = "lock_time_limit".localized
    var no_limit = "no_limit".localized
    var h24 = "h24".localized
    var h36 = "h36".localized
    var h48 = "h48".localized
    var h60 = "h60".localized
    var h72 = "h72".localized
    var last_unlock_time = "last_unlock_time".localized
    var sync_with_node = "sync_with_node".localized
    var rescan = "rescan".localized
    var rescan_text = "rescan_text".localized
    var mobile_node_title = "mobile_node_title".localized
    var mobile_node_text = "mobile_node_text".localized
    var receive_contact_placholder = "receive_contact_placholder".localized
    var copy_and_close = "copy_and_close".localized.lowercased()
    var enter_name_save = "enter_name_save".localized
    var add_max = "add_max".localized.lowercased()
    var online_mobile_node = "online_mobile_node".localized.lowercased()
    var connect = "connect".localized.lowercased()

    var random_node_title = "random_node_title".localized
    var fast_sync = "fast_sync".localized
    var random_node_text = "random_node_text".localized

    var slow_sync = "slow_sync".localized
    var mobile_node_hint = "mobile_node_hint".localized

    var own_node_title = "own_node_title".localized
    var fast_secure_advance = "fast_secure_advance".localized
    var own_node_text = "own_node_text".localized

    var connect_to_mobilenode = "connect_to_mobilenode".localized
    var syncing_with_blockchain = "syncing_with_blockchain".localized
    var please_no_lock = "please_no_lock".localized
    var wallet_connected_to_mobile_node = "wallet_connected_to_mobile_node".localized
    var disconnect = "disconnect".localized
    var start_using_wallet = "start_using_wallet".localized
    var enter_node_address = "enter_node_address".localized
    var senf_offline_notice = "senf_offline_notice".localized
    var regular_online_only = "regular_online_only".localized
    var regular_offline_only = "regular_offline_only".localized
    var sender_choice = "sender_choice".localized
    var assets = "assets".localized
    
    var usage_recent_old = "usage_recent_old".localized
    var usage_old_recent = "usage_old_recent".localized
    var amount_large_small = "amount_large_small".localized
    var amount_small_large = "amount_small_large".localized
    var usd_small_large = "usd_small_large".localized
    var usd_large_small = "usd_large_small".localized
    
    var balance = "balance".localized
    var asset_info = "asset_info".localized
    var locked = "locked".localized

    var small_unit_unit = "small_unit_unit".localized
    var ratio = "ratio".localized
    var short_desc = "short_desc".localized
    var long_desc = "long_desc".localized
    var desc_paper = "desc_paper".localized
    var website = "website".localized
    var beam_conf_asset = "beam_conf_asset".localized
    var more_details = "more_details".localized
    var time_ear_last = "time_ear_last".localized
    var time_last_ear = "time_last_ear".localized
    var remaining_beam = "remaining_beam".localized
    var failed = "failed".localized
    var clear_wallet = "clear_wallet".localized

    var advanced = "advanced".localized
    var maximum_anonymity_set = "maximum_anonymity_set".localized
    var receive_description = "receive_description".localized
    var maximum_anonymity = "maximum_anonymity".localized
    var connect_node_offline = "connect_node_offline".localized
    var max_privacy_fee = "max_privacy_fee".localized
    var transaction_time = "transaction_time".localized
    var transaction_indefinitely = "transaction_indefinitely".localized
    var online_sbbs_address = "online_sbbs_address".localized
    var copy_address_close = "copy_address_close".localized
    var about_sbbs = "about_sbbs".localized
    var max_anonymity_address = "max_anonymity_address".localized
    var regular_address = "regular_address".localized
    var online_address = "online_address".localized
    var offline_left_address = "offline_left_address".localized
    var offline_left_address_warning = "offline_left_address_warning".localized
    var send_offline_hint = "send_offline_hint".localized
    var send_max_privacy_title = "send_max_privacy_title".localized
    var send_notice_max_privacy = "send_notice_max_privacy".localized
    var online_new_status = "online_new_status".localized
    var receive_description_2 = "receive_description_2".localized
    var only_online_support = "only_online_support".localized
    var max_funds_error = "max_funds_error".localized
    var max_funds_hint = "max_funds_hint".localized
    var dAppStore = "dAppStore".localized
    var fee = "fee".localized
    var confirm_accept = "confirm_accept".localized
    var will_take_funds = "will_take_funds".localized
    var will_send_funds = "will_send_funds".localized
    
    public func new_version_available_title(version: String) -> String {
        return "new_version_available_title".localized.replacingOccurrences(of: "(version)", with: version)
    }
    
    public func new_version_available_detail(version: String) -> String {
        return "new_version_available_detail".localized.replacingOccurrences(of: "(version)", with: version)
    }
    
    public func transaction_received_notif_body(_ beam:String, address:String) -> String {
        return "transaction_received_notif_body".localized.replacingOccurrences(of: "(value)", with: beam).replacingOccurrences(of: "(address)", with: address)
    }
    
    public func transaction_sent_notif_body(_ beam:String, address:String) -> String {
        return "transaction_sent_notif_body".localized.replacingOccurrences(of: "(value)", with: beam).replacingOccurrences(of: "(address)", with: address)
    }
    
    public func transaction_receiving_notif_body(_ beam:String, address:String, failed:Bool) -> NSMutableAttributedString {
        let string = !failed ? "transaction_receiving_notif_body".localized.replacingOccurrences(of: "(value)", with: beam).replacingOccurrences(of: "(address)", with: address) : "transaction_received_notif_body_failed".localized.replacingOccurrences(of: "(value)", with: beam).replacingOccurrences(of: "(address)", with: address).replacingOccurrences(of: "  ", with: " ")
        
        let rangeBeam = (string as NSString).range(of: String(beam))
        let rangeAddress = (string as NSString).range(of: String(address))
        
        let attributedText = NSMutableAttributedString(string: string)
        attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: rangeBeam)
        attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: rangeAddress)
        return attributedText
    }
    
    public func muttableTransaction_received_notif_body(_ beam:String, address:String, failed:Bool) -> NSMutableAttributedString {
        var addressString = address
        if address == "0" {
            addressString = "shielded pool"
        }
        let string = !failed ? "transaction_received_notif_body".localized.replacingOccurrences(of: "(value)", with: beam).replacingOccurrences(of: "(address)", with: addressString) : "transaction_received_notif_body_failed".localized.replacingOccurrences(of: "(value)", with: beam).replacingOccurrences(of: "(address)", with: addressString).replacingOccurrences(of: "  ", with: " ")
        
        let rangeBeam = (string as NSString).range(of: String(beam))
        let rangeAddress = (string as NSString).range(of: String(addressString))
        
        let attributedText = NSMutableAttributedString(string: string)
        attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: rangeBeam)
        attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: rangeAddress)
        return attributedText
    }
    
    public func muttableTransaction_sent_notif_body(_ beam:String, address:String, failed:Bool) -> NSMutableAttributedString {
        let string = !failed ? "transaction_sent_notif_body".localized.replacingOccurrences(of: "(value)", with: beam).replacingOccurrences(of: "(address)", with: address) : "transaction_sent_notif_body_failed".localized.replacingOccurrences(of: "(value)", with: beam).replacingOccurrences(of: "(address)", with: address).replacingOccurrences(of: "  ", with: " ")
        
        
        let rangeBeam = (string as NSString).range(of: String(beam))
        let rangeAddress = (string as NSString).range(of: String(address))
        
        let attributedText = NSMutableAttributedString(string: string)
        attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: rangeBeam)
        attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: rangeAddress)
        return attributedText
    }
    
    public func addresses_expired_notif(count:Int) -> String {
        return "addresses_expired_notif".localized.replacingOccurrences(of: "(count)", with: String(count))
    }
    
    public func assets_sent(name:String) -> String {
        return String.init(format: "assets_sent".localized, name)
    }

    public func minAmount(str:String) -> String {
        return "min_amount".localized + " " + str
    }
    
    public func delete_category_text(str:String) -> String {
        return "delete_category_text".localized.replacingOccurrences(of: "(str)", with: str)
    }
    
    public func delete_data_text(str:String) -> String {
        return "delete_all_text".localized.replacingOccurrences(of: "(str)", with: str)
    }
    
    public func beam_amount(_ str:String) -> String {
        return str // + " BEAM"
    }
    
    public func cannot_connect_node(_ node:String) -> String {
        return "canot_connect_node".localized.lowercased() + ": " + node
    }
    
    public func buy_send_money(value:String, name:String) -> String {
        return "buy_beam_value".localized.lowercased().replacingOccurrences(of: "(value)", with: value).replacingOccurrences(of: "(name)", with: name).uppercased()
    }
    
    public func addDots(value:String) -> String {
        return value + ":"
    }
}
