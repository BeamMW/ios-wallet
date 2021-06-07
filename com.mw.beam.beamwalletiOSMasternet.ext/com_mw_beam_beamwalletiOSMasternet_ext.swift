//
//  com_mw_beam_beamwalletiOSMasternet_ext.swift
//  com.mw.beam.beamwalletiOSMasternet.ext
//
//  Created by Denis on 17.05.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import WidgetKit
import SwiftUI

struct CommitLoader {
//    static func fetch(completion: @escaping (Result<Commit, Error>) -> Void) {
//        let branchContentsURL = URL(string: "https://api.github.com/repos/apple/swift/branches/main")!
//        let task = URLSession.shared.dataTask(with: branchContentsURL) { (data, response, error) in
//            guard error == nil else {
//                completion(.failure(error!))
//                return
//            }
//            let commit = getCommitInfo(fromData: data!)
//            completion(.success(commit))
//        }
//        task.resume()
//    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct com_mw_beam_beamwalletiOSMasternet_extEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

@main
struct com_mw_beam_beamwalletiOSMasternet_ext: Widget {
    let kind: String = "com_mw_beam_beamwalletiOSMasternet_ext"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            com_mw_beam_beamwalletiOSMasternet_extEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct com_mw_beam_beamwalletiOSMasternet_ext_Previews: PreviewProvider {
    static var previews: some View {
        com_mw_beam_beamwalletiOSMasternet_extEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
