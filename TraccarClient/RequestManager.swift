//
// Copyright 2015 - 2017 Anton Tananaev (anton.tananaev@gmail.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

public class RequestManager: NSObject {
    
    public static func sendRequest(_ url: URL, auth:String, completionHandler handler: @escaping (Bool) -> Void) {
		let loginString = auth
		let loginData = loginString.data(using: String.Encoding.utf8)!
		let base64LoginString = loginData.base64EncodedString()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main, completionHandler: {(response, data, connectionError) -> Void in
            handler(data != nil)
        })

/*
		//swift 2
	    var request = NSMutableURLRequest(URL: NSURL(string: "YOUR URL")!)
	    var session = NSURLSession.sharedSession()
	    request.HTTPMethod = "POST"

	    var params = ["username":"username", "password":"password"] as Dictionary<String, String>

	    request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(params, options: [])

	    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
	    request.addValue("application/json", forHTTPHeaderField: "Accept")

	    var task = session.dataTaskWithRequest(request, completionHandler: {(response, data, connectionError) -> Void in
            handler(data != nil)
        })

	    task.resume()
*/
    }

}
