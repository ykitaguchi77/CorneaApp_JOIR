//
//  ContentView.swift
//  CorneaApp
//
//  Created by Yoshiyuki Kitaguchi on 2021/04/18.
//
//写真Coredata参考サイト：https://tomato-develop.com/swiftui-camera-photo-library-core-data/
//
import SwiftUI
import CoreData

//変数を定義
class User : ObservableObject {
    @Published var date: Date = Date()
    @Published var id: String = ""
    @Published var hashid: String = ""
    @Published var selected_gender: Int = 0
    @Published var selected_side: Int = 0
    @Published var selected_hospital: Int = 0
    @Published var selected_disease: Int = 0
    @Published var free_disease: String = ""
    @Published var ssmixpath: String = "" //JOIR転送用フォルダ
    @Published var gender: [String] = ["", "男", "女"]
    @Published var birthdate: String = ""
    @Published var side: [String] = ["", "右", "左"]
    @Published var sidecode: [String] = ["N", "R", "L"]
    @Published var hospitals: [String] = ["", "筑波大", "大阪大", "東京歯科大市川", "鳥取大", "宮田眼科", "順天堂大", "ツカザキ病院", "広島大", "新潟大", "富山大", "福島県立医大", "東京医大"]
    @Published var hospitalcode: [String] = ["", "5110051", "9900249", "2712404", "8010028", "0211008", "0514836", "4009334", "8010017", "8910011", "8010035", "0116930", "0415018"]
    @Published var disease: [String] = ["", "正常", "", "<<感染性>>", "アメーバ", "細菌", "真菌", "上皮型ヘルペス", "", "<<非感染性>>", "カタル性角膜浸潤", "実質型ヘルペス", "フリクテン", "モーレン潰瘍", "非感染その他", "", "<<腫瘍>>", "翼状片", "角結膜腫瘍", "", "<<沈着>>", "アミロイドーシス", "帯状角膜変性", "顆粒状角膜ジストロフィー", "格子状角膜ジストロフィー", "膠様滴状角膜ジストロフィー", "斑状角膜ジストロフィー", "瞼裂斑", "", "<<その他>>","瘢痕", "水疱性角膜症", "白内障", "緑内障発作", "分類不能（自由記載）"]
    @Published var imageNum: Int = 0 //写真の枚数（何枚目の撮影か）
    @Published var isNewData: Bool = false
    @Published var isSendData: Bool = false
    @Published var sourceType: UIImagePickerController.SourceType = .camera //撮影モードがデフォルト
    @Published var equipmentVideo: Bool = false //video or camera 撮影画面のマージ指標変更のため
    }


struct ContentView: View {
    @ObservedObject var user = User()
    //CoreDataの取り扱い
    @Environment(\.managedObjectContext) private var viewContext

    @State private var goTakePhoto: Bool = false  //撮影ボタン
    @State private var isPatientInfo: Bool = false  //患者情報入力ボタン
    @State private var goSendData: Bool = false  //送信ボタン
    @State private var uploadData: Bool = false  //Loadボタン
    @State private var newPatient: Bool = false  //新規ボタン
    
    
    var body: some View {
        VStack(spacing:0){
            Text("Cornea app")
                .font(.largeTitle)
                .padding(.bottom)
            
            Image("IMG_1273")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            
            Button(action: {
                //病院番号はアプリを落としても保存されるようにしておく
                self.user.selected_hospital = UserDefaults.standard.integer(forKey: "hospitaldefault")
                self.isPatientInfo = true /*またはself.show.toggle() */
                
            }) {
                HStack{
                    Image(systemName: "info.circle")
                    Text("患者情報入力")
                }
                    .foregroundColor(Color.white)
                    .font(Font.largeTitle)
            }
                .frame(minWidth:0, maxWidth:CGFloat.infinity, minHeight: 75)
                .background(Color.black)
                .padding()
            .sheet(isPresented: self.$isPatientInfo) {
                Informations(user: user)
                //こう書いておかないとmissing as ancestorエラーが時々でる
            }
            
            
                
            Button(action: {
                self.user.sourceType = UIImagePickerController.SourceType.camera
                self.user.equipmentVideo = false
                self.goTakePhoto = true /*またはself.show.toggle() */
                self.user.isSendData = false //撮影済みを解除
                ResultHolder.GetInstance().SetMovieUrls(Url: "")  //動画の保存先をクリア
            }) {
                HStack{
                    Image(systemName: "camera")
                    Text("撮影")
                }
                    .foregroundColor(Color.white)
                    .font(Font.largeTitle)
            }
                .frame(minWidth:0, maxWidth:CGFloat.infinity, minHeight: 75)
                .background(Color.black)
                .padding()
            .sheet(isPresented: self.$goTakePhoto) {
                CameraPage(user: user)
            }
        
            
            //送信するとボタンの色が変わる演出
            if self.user.isSendData {
                Button(action: {self.goSendData = true /*またはself.show.toggle() */}) {
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
                .sheet(isPresented: self.$goSendData) {
                    SendData(user: user)
                }
            } else {
                Button(action: { self.goSendData = true /*またはself.show.toggle() */ }) {
                    HStack{
                        Image(systemName: "square.and.arrow.up")
                        Text("送信")
                    }
                        .foregroundColor(Color.white)
                        .font(Font.largeTitle)
                }
                    .frame(minWidth:0, maxWidth:CGFloat.infinity, minHeight: 75)
                    .background(Color.black)
                    .padding()
                .sheet(isPresented: self.$goSendData) {
                    SendData(user: user)
                }
            }
            
            HStack{
            Button(action: {
                self.user.sourceType = UIImagePickerController.SourceType.photoLibrary
                self.user.isSendData = false //撮影済みを解除
                self.uploadData = true /*またはself.show.toggle() */
                
            }) {
                HStack{
                    Image(systemName: "folder")
                    Text("Load")
                }
                    .foregroundColor(Color.white)
                    .font(Font.largeTitle)
            }
                .frame(minWidth:0, maxWidth:200, minHeight: 75)
                .background(Color.black)
                .padding()
            .sheet(isPresented: self.$uploadData) {
                CameraPage(user: user)
            }
            
            Button(action: { self.newPatient = true /*またはself.show.toggle() */ }) {
                HStack{
                    Image(systemName: "stop.circle")
                    Text("次患者")
                }
                    .foregroundColor(Color.white)
                    .font(Font.largeTitle)
            }
            .alert(isPresented:$newPatient){
                Alert(title: Text("データをクリアしますか？"), primaryButton:.default(Text("はい"),action:{
                    //データの初期化
                    self.user.date = Date()
                    self.user.id = ""
                    self.user.birthdate = ""
                    self.user.imageNum = 0
                    self.user.selected_gender = 0
                    self.user.selected_side = 0
                    self.user.selected_hospital = 0
                    self.user.selected_disease = 0
                    self.user.free_disease = ""
                    self.user.isSendData = false
                    self.user.ssmixpath = ""
                    
                    
                }),
                      secondaryButton:.destructive(Text("いいえ"), action:{}))
                }
                .frame(minWidth:0, maxWidth:200, minHeight: 75)
                .background(Color.black)
                .padding()
            }
        }
    }
}
