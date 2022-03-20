//
//  SendData.swift
//  CorneaApp
//
//  Created by Yoshiyuki Kitaguchi on 2021/04/18.
//  フォルダ作成と保存　https://qiita.com/Hyperbolic_____/items/a4581ed08cec4c7df9ea
//
import SwiftUI
import CoreData
import CryptoKit
import AVKit

struct SendData: View {
    @ObservedObject var user: User
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showingAlert: Bool = false
        
    var body: some View {
        
        VStack{
                GeometryReader { bodyView in
                    VStack{
                        ScrollView{
                            Text("内容を確認してください").padding().foregroundColor(Color.black)
                                .font(Font.title)
                            
                            ZStack{
                                if ResultHolder.GetInstance().GetMovieUrls() == "" {
                                    GetImageStack(images: ResultHolder.GetInstance().GetUIImages(), shorterSide: GetShorterSide(screenSize: bodyView.size))
                                }else{
                                    let player = AVPlayer(url: URL(string:ResultHolder.GetInstance().GetMovieUrls())!)
                                    VideoPlayer(player: player).frame(width: bodyView.size.width, height:bodyView.size.width)
                                }
                                
                            }
                            
                            HStack{
                                Text("撮影日時:")
                                Text(self.user.date, style: .date)
                            }
                            Text("ID: \(self.user.id)")
                            Text("施設: \(self.user.hospitals[user.selected_hospital])")
                            Text("診断名: \(user.disease[user.selected_disease])")
                            Text("自由記載: \(self.user.free_disease)")
                        }
                    }
                }

                Spacer()

            
            //送信するとボタンの色が変わる演出
            if self.user.isSendData {
                Button(action: {}) {
                    HStack{
                        Image(systemName: "square.and.arrow.up")
                        Text("送信済み")
                    }
                        .foregroundColor(Color.white)
                        .font(Font.largeTitle)
                }
                    .frame(minWidth:0, maxWidth:CGFloat.infinity, minHeight: 75)
                    .background(Color.blue)
                    .padding()
            } else if (self.user.id.isEmpty || self.user.side[user.selected_side].isEmpty || self.user.hospitals[user.selected_hospital].isEmpty || self.user.disease[user.selected_disease].isEmpty || self.user.gender[user.selected_gender].isEmpty || self.user.birthdate.isEmpty){
                Button(action: {
                    print("id: \(user.id)")
                    print("side: \(user.side[user.selected_side])")
                    print("hospital \(user.hospitals[user.selected_hospital])")
                    print("disease: \(user.disease[user.selected_disease])")
                    print("side: \(user.gender[user.selected_gender])")
                    print("birthdate: \(user.birthdate)")
                    showingAlert = true //空欄があるとエラー
                }) {
                    HStack{
                        Image(systemName: "square.and.arrow.up")
                        Text("送信")
                    }
                        .foregroundColor(Color.white)
                        .font(Font.largeTitle)
                }
                    .alert(isPresented: $showingAlert){Alert(title: Text("項目に空欄があります"))}
                    .frame(minWidth:0, maxWidth:CGFloat.infinity, minHeight: 75)
                    .background(Color.black)
                    .padding()
            } else if (self.user.birthdate.count != 8){
                Button(action: {
                    print("birthdate: \(user.birthdate)")
                    showingAlert = true //空欄があるとエラー
                }) {
                    HStack{
                        Image(systemName: "square.and.arrow.up")
                        Text("送信")
                    }
                        .foregroundColor(Color.white)
                        .font(Font.largeTitle)
                }
                    .alert(isPresented: $showingAlert){Alert(title: Text("生年月日は8桁で入力して下さい"))}
                    .frame(minWidth:0, maxWidth:CGFloat.infinity, minHeight: 75)
                    .background(Color.black)
                    .padding()
            } else{
                Button(action: {
                showingAlert = false
                GenerateHashID()
                SaveToResultHolder()
                ssmix2Folder() //保存用のフォルダを作成
                createXml()
                SaveToDoc()
                self.user.isSendData = true
                self.user.imageNum += 1 //画像番号を増やす
                self.presentationMode.wrappedValue.dismiss()
               })
                {
                    HStack{
                        Image(systemName: "square.and.arrow.up")
                        Text("送信")
                    }
                        .foregroundColor(Color.white)
                        .font(Font.largeTitle)
                }
                    .alert(isPresented: $showingAlert){Alert(title: Text("項目に空欄があります"))}
                    .frame(minWidth:0, maxWidth:CGFloat.infinity, minHeight: 75)
                    .background(Color.black)
                    .padding()
            }
        }
    }
            
    
//    public func GenerateHashID(){
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "ja_JP")
//        dateFormatter.dateStyle = .medium
//        dateFormatter.dateFormat = "yyyyMMdd"
//
//        //newdateid: 20211204-11223344-3
//        let newdateid = "\(dateFormatter.string(from:self.user.date))-\(self.user.id)-\(self.user.imageNum)"
//        let dateid = Data(newdateid.utf8)
//        let hashid = SHA256.hash(data: dateid)
//        user.hashid = hashid.compactMap { String(format: "%02x", $0) }.joined()
//        print(user.hashid)
//    }
    
    //JOIRのHASH化プロトコル
    public func GenerateHashID(){
        let id = self.user.id
        let gender = self.user.gender[user.selected_gender]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        var birthdate = self.user.birthdate
        birthdate.insert("-", at: birthdate.index(birthdate.startIndex, offsetBy: 6))
        birthdate.insert("-", at: birthdate.index(birthdate.startIndex, offsetBy: 4))

        let hospitalcode = self.user.hospitalcode[user.selected_gender]
        let newid = id + gender + birthdate + hospitalcode
        let dateid = Data(newid.utf8)
        let hashid = SHA256.hash(data: dateid)
        user.hashid = hashid.compactMap { String(format: "%02x", $0) }.joined()

        print("Generated hashid: \(user.hashid)")
    }
    
    //ResultHolderにテキストデータを格納
    public func SaveToResultHolder(){
        //var imagenum: String = String(user.imageNum)
        ResultHolder.GetInstance().SetAnswer(q1: stringDate(date: self.user.date), q2: user.hashid, q3: user.id, q4: self.numToString(num: self.user.imageNum), q5: self.user.side[user.selected_side], q6: self.user.hospitals[user.selected_hospital], q7: self.user.disease[user.selected_disease], q8: self.user.free_disease, q9: self.user.gender[user.selected_gender], q10: self.user.birthdate)
    }
    
    public func stringDate(date:Date)->String{
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let stringDate = df.string(from: date)
        return stringDate
    }
    
    public func numToString(num:Int)->String{
        let string: String = String(num)
        return string
    }

    
    

    //private func saveToDoc (image: UIImage, fileName: String ) -> Bool{
    public func SaveToDoc () -> Bool{
        let images = ResultHolder.GetInstance().GetUIImages()
        let jsonfile = ResultHolder.GetInstance().GetAnswerJson()
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photoURL = documentsURL.appendingPathComponent(imageName()+".png")
        let movieURL = documentsURL.appendingPathComponent(imageName()+".mp4")
        let ssmixURL = URL(string: self.user.ssmixpath)!
        let ssmixPhotoURL = ssmixURL.appendingPathComponent(imageName()+".png")
        let ssmixMovieURL = ssmixURL.appendingPathComponent(imageName()+".mp4")
                
//        let testURL = "file://" + NSHomeDirectory() + "/Documents/test"
//        do{
//            try FileManager.default.createDirectory(atPath: testURL,  withIntermediateDirectories: true, attributes: nil)
//        }catch {
//            print("フォルダ作成に失敗 error=(error)")
//        }
//        let testURL2 = URL(string: testURL)
//        let testJsonURL = testURL2!.appendingPathComponent("aaa"+".png")
//
//        print("testURL \(testURL)")
//        print("testJsonURL \(testJsonURL)")
        
        //動画が保存されていない場合
        if ResultHolder.GetInstance().GetMovieUrls() == ""{
            //pngを保存
            for i in 0..<images.count{
                let pngImageData = UIImage.pngData(images[i])
                // jpgで保存する場合
                // let jpgImageData = UIImageJPEGRepresentation(image, 1.0)
                do {
                    try pngImageData()!.write(to: photoURL)
                    print("successfully saved PNG to doc")
                } catch {
                    //エラー処理
                    print("image save error")
                    return false
                }
                
                print("ssmixPhotoURL: \(ssmixPhotoURL)")
                do {
                    try pngImageData()!.write(to: ssmixPhotoURL)
                    print("successfully saved PNG to doc (ssmix)")
                    
                } catch {
                    print("image save error (ssmix)")
                    //エラー処理
                    return false
                }
            }
        }else{
            //動画が保存されている場合
            //mp4を保存
            let fileType: AVFileType = AVFileType.mp4
            // 動画をエクスポートする
            exportMovie(sourceURL: URL(string:ResultHolder.GetInstance().GetMovieUrls())!, destinationURL: movieURL, fileType: fileType)
            exportMovie(sourceURL: URL(string:ResultHolder.GetInstance().GetMovieUrls())!, destinationURL: ssmixMovieURL, fileType: fileType)
        }
            
            
        //jsonを保存
        let jsonURL = documentsURL.appendingPathComponent(imageName()+".json")
        let ssmixJsonURL = ssmixURL.appendingPathComponent(imageName()+".json")
        
        print("ssmixJsonURL: \(ssmixJsonURL)")
        do {
            try jsonfile.write(to: jsonURL, atomically: true, encoding: String.Encoding.utf8)
            print("successfully saved json to doc")
        } catch {
            //エラー処理
            print("Jsonを保存できませんでした")
            return false
        }
        
//        //ssmixフォルダ内にjsonを保存→XMLを保存することとなったのでdeprecated
//        do {
//            try jsonfile.write(to: ssmixJsonURL, atomically: true, encoding: .utf8)
//            print("successfully saved json to doc (ssmix)")
//        } catch {
//            //エラー処理
//            print("Jsonを保存できませんでした (ssmix)")
//            return false
//        }
        
        return true
    }
        

    public func GetImageStack(images: [UIImage], shorterSide: CGFloat) -> some View {
            let padding: CGFloat = 10.0
            let imageLength = shorterSide / 3 + padding * 2
            let colCount = Int(shorterSide / imageLength)
            let rowCount = Int(ceil(Float(images.count) / Float(colCount)))
            return VStack(alignment: .leading) {
                ForEach(0..<rowCount){
                    i in
                    HStack{
                        ForEach(0..<colCount){
                            j in
                            if (i * colCount + j < images.count){
                                let image = images[i * colCount + j]
                                Image(uiImage: image).resizable().frame(width: imageLength*2.4, height: imageLength*2.4).padding(padding)
                            }
                        }
                    }
                }
            }
            .border(Color.black)
        }
    
    public func GetShorterSide(screenSize: CGSize) -> CGFloat{
        let shorterSide = (screenSize.width < screenSize.height) ? screenSize.width : screenSize.height
        return shorterSide
    }
    

        
    //JOIRの画像命名
    public func imageName() -> String{
        let id = self.user.hashid
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let examDate = dateFormatter.string(from: self.user.date)
        let kind = "SUMAHO"
        let side = self.user.sideCode[user.selected_side]
        let imageNum = String(format: "%03d", self.user.imageNum)
        let imageName = id + "_" + examDate + "_" + kind + "_" + side + "_" + imageNum
        //print(imageName)
        return imageName
    }
    
    
    //xmlファイルを作成
    public func createXml(){
        
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "yyyyMMdd"
        dateFormatter1.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter1.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let examDate1 = dateFormatter1.string(from: self.user.date)
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd"
        dateFormatter2.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter2.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let examDate2 = dateFormatter2.string(from: self.user.date)
        
        let dateFormatter3 = DateFormatter()
        dateFormatter3.dateFormat = "HH:mm:SS"
        dateFormatter3.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter3.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let examTime = dateFormatter3.string(from: self.user.date)
        
        let id = self.user.hashid
        let gender = self.user.genderCode[user.selected_gender]
        let side = self.user.side[user.selected_side]
        //dateOfBirth 19780208 -> 1978-02-08 に整形
        var dob = self.user.birthdate
        let insertIdx1 = dob.index(dob.startIndex, offsetBy: 6)
        let insertIdx2 = dob.index(dob.startIndex, offsetBy: 4)
        dob.insert(contentsOf: "-", at: insertIdx1)
        dob.insert(contentsOf: "-", at: insertIdx2)
        
        let fileName = imageName()
        var fileNameExt = "aaa"
        if ResultHolder.GetInstance().GetMovieUrls() == ""{
            fileNameExt = ".png"
        }else{
            fileNameExt = ".mp4"
        }
                
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let ssmixURL = URL(string: self.user.ssmixpath)!
        let ssmixXmlURL = ssmixURL.appendingPathComponent(self.user.hashid+"_\(examDate1)_SUMAHO.xml")
        let ssmixXmlURLPath = ssmixXmlURL.path
        
        //XMLファイルがあるかどうかを確認する
        if FileManager.default.fileExists(atPath:ssmixXmlURLPath){
            print("file exists")
            guard let str = try? String(contentsOf: ssmixXmlURL) else {
                fatalError("ファイル読み込みエラー")}
            let result = str.range(of:"        </nsCORNEA:CORNEA>")
            
            if let theRange = result {
                let latter = str[theRange.lowerBound...]
                //print(latter)
                let former = str.prefix(str.utf16.count - latter.utf16.count)
                print(former)
                
                var i=1
     
                for i in 1...100 {
                    var contain: Bool = former.contains("No=\"\(i)\"")
                    if contain == true{
                        print("\(i) is present")
                    } else {
                        print("\(i) is not present")
                        var insert = """
                            <nsCORNEA:List No=\"\(i)\">
                                        <nsCORNEA:ImageType></nsCORNEA:ImageType>
                                        <nsCORNEA:AcquisitionDate>\(examDate2)</nsCORNEA:AcquisitionDate>
                                        <nsCORNEA:AcquisitionTime>\(examTime)</nsCORNEA:AcquisitionTime>
                                        <nsCORNEA:Timer></nsCORNEA:Timer>
                                        <nsCORNEA:HorizontalFieldOfView></nsCORNEA:HorizontalFieldOfView>
                                        <nsCORNEA:ImageLaterality>\(side)</nsCORNEA:ImageLaterality>
                                        <nsCORNEA:PixelSpacing unit="mm"></nsCORNEA:PixelSpacing>
                                        <nsCORNEA:FileName>\(fileName).\(fileNameExt)</nsCORNEA:FileName>
                                    </nsCORNEA:List>
                        
                        """
                        var str = former + insert + latter
                        //print(str)
                        do {
                             try str.write(to: ssmixXmlURL, atomically: true, encoding: .utf8)
                             print("xml file successfully renewed!")
                         } catch {
                             print("Error: \(error)")
                        }
                        break
                    }
                }
            }
        } else {
            print("file does not exist")
            let str = """
                   <?xml version="1.0" encoding="UTF-8"?>
                   <?xml-stylesheet type="text/xsl" href="Fundus_Stylesheet.xsl"?>
                   
                   <Ophthalmology xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:nsCommon="http://www.joia.or.jp/standardized/namespaces/Common" xmlns:nsCORNEA="http://www.joia.or.jp/standardized/namespaces/Cornea" xsi:schemaLocation="http://www.joia.or.jp/standardized/namespaces/Common Common_schema.xsd
                   http://www.joia.or.jp/standardized/namespaces/Fundus Fundus_schema.xsd">
                   
                        <nsCommon:Common>
                            <nsCommon:Compnany>Apple</nsCommon:Compnany>
                            <nsCommon:ModelName>iPhone13pro</nsCommon:ModelName>
                            <nsCommon:MachineNo></nsCommon:MachineNo>
                            <nsCommon:ROMVersion></nsCommon:ROMVersion>
                            <nsCommon:Version></nsCommon:Version>
                            <nsCommon:Date>\(examDate2)</nsCommon:Date>
                            <nsCommon:Time>\(examTime)</nsCommon:Time>
                   
                            <nsCommon:Patient>
                               <nsCommon:No.></nsCommon:No.>
                               <nsCommon:ID>\(id)</nsCommon:ID>
                               <nsCommon:FirstName></nsCommon:FirstName>
                               <nsCommon:LastName></nsCommon:LastName>
                               <nsCommon:Sex>\(gender)</nsCommon:Sex>
                               <nsCommon:Age></nsCommon:Age>
                               <nsCommon:DOB>\(dob)</nsCommon:DOB>
                               <nsCommon:NameJ1></nsCommon:NameJ1>
                               <nsCommon:NameJ2></nsCommon:NameJ2>
                            </nsCommon:Patient>
                            <nsCommon:Operator>
                               <nsCommon:No.></nsCommon:No.>
                               <nsCommon:ID></nsCommon:ID>
                            </nsCommon:Operator>
                        </nsCommon:Common>
                   
                        <nsCORNEA:Measure type="SUMAHO">
                            <nsCORNEA:CORNEA>
                                <nsCORNEA:List No="1">
                                    <nsCORNEA:ImageType></nsCORNEA:ImageType>
                                    <nsCORNEA:AcquisitionDate>\(examDate2)</nsCORNEA:AcquisitionDate>
                                    <nsCORNEA:AcquisitionTime>\(examTime)</nsCORNEA:AcquisitionTime>
                                    <nsCORNEA:Timer></nsCORNEA:Timer>
                                    <nsCORNEA:HorizontalFieldOfView></nsCORNEA:HorizontalFieldOfView>
                                    <nsCORNEA:ImageLaterality></nsCORNEA:ImageLaterality>
                                    <nsCORNEA:PixelSpacing unit="mm"></nsCORNEA:PixelSpacing>
                                    <nsCORNEA:FileName>\(fileName)\(fileNameExt)</nsCORNEA:FileName>
                                </nsCORNEA:List>
                            </nsCORNEA:CORNEA>
                         </nsCORNEA:Measure>
                   </Ophthalmology>
                   """
            do {
                 try str.write(to: ssmixXmlURL, atomically: true, encoding: .utf8)
                 print("xml file successfully created!")
             } catch {
                 print("Error: \(error)")
             }
        }
     }
    
    
    public func ssmix2Folder(){
        //1回目のみフォルダを作成する。すでにフォルダがあればそこに追加保存する
        if self.user.ssmixpath.isEmpty{
            //document folderのパス
            let dir = NSHomeDirectory() + "/Documents"
            
            //追加するフォルダの名前を定義
            let id = self.user.hashid
            //let id1 = self.user.hashid.prefix(3) //最初の3文字
            //let id2 = self.user.hashid.dropFirst(3).prefix(3) //3から6文字目
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            let examDate = dateFormatter.string(from: self.user.date)
            
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "yyyyMMddHHmmSSfff"
            dateFormatter2.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter2.timeZone = TimeZone(identifier: "Asia/Tokyo")
            let examDate2 = dateFormatter2.string(from: self.user.date)
            let orderNum = examDate2.dropFirst(1) //2文字目から。yyyMMddHHmmSSfff
            
            let hospitalAbb = self.user.hospitalsAbbreviated[user.selected_hospital]
            
            let dataType = "SUMAHO"
            let maker = "APL"
            let deviceName = "000"
            let keyInfo = self.user.hospitalcode[user.selected_hospital] + maker + String(deviceName) + String(orderNum)
            let contentsFolder = id + "_" + examDate + "_" + dataType + "_" + keyInfo + "_" + examDate2 + "_26_1"
            let folderPath = "\(dir)/\(hospitalAbb)/\(contentsFolder)"

            print(folderPath)
            
            let fileManager = FileManager.default
            do{
                try fileManager.createDirectory(atPath: folderPath,  withIntermediateDirectories: true, attributes: nil)
                self.user.ssmixpath = "file://"+folderPath //保存処理の際に使いやすいよう、フルパスに直して保存
                
                print(user.ssmixpath)
            }catch {
                print("フォルダ作成に失敗 error=(error)")
            }
        }else{
            print("SSMIX folder already exists!")
        }

    }
    
    func exportMovie(sourceURL: URL, destinationURL: URL, fileType: AVFileType) -> Void {

        let asset = AVAsset(url: sourceURL)

            let mixComposition = AVMutableComposition()

            let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)

            try! videoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: CMTime.zero)

            let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

                if let track = asset.tracks(withMediaType: .audio).first {

                    do {
                        try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: track, at: .zero)
                    } catch {
                        print("error")
                    }

                } else {
                    mixComposition.removeTrack(audioTrack!)
                    print("no audio detected, removed the track")
                }

        // エクスポートするためのセッションを作成
        let assetExport = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)

        // エクスポートするファイルの種類を設定
        assetExport?.outputFileType = fileType

        // エクスポート先URLを設定
        assetExport?.outputURL = destinationURL

        // エクスポート先URLに既にファイルが存在していれば、削除する (上書きはできないようなので)
//        if FileManager.default.fileExists(atPath: (assetExport?.outputURL?.path)!) {
//            try! FileManager.default.removeItem(atPath: (assetExport?.outputURL?.path)!)
//        }
        // エクスポートする
        assetExport?.exportAsynchronously(completionHandler: {
            // エクスポート完了後に実行したいコードを記述
            print("successfully exported mp4 to doc")
        })

    }
                                           

    
}


//ビデオ再生ビュー
struct PlayerView: UIViewRepresentable {
    let player: AVPlayer

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
    }

    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(player: player)
    }

}


class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

}
                                           
                                        
