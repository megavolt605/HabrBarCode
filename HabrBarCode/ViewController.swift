
import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    
    var captureSession: AVCaptureSession? // наша сессия для захвата видео с камеры
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? // слой для отображения видео с камеры
    var audioPlayer: AVAudioPlayer? // будем щелкать звуком "затвора" при обнаружении кода
    var isActive: Bool = false // признак того, что мы сейчас в режиме поиска кода
    
    @IBAction func startStopButtonTouchUpInside(sender: AnyObject) {
        if isActive {
            stopRec()
        } else {
            startRec()
        }
    }
    
    // это можно стелать и в другом месте, но я решил тут
    override func viewDidLoad() {
        super.viewDidLoad()
        let path = NSBundle.mainBundle().pathForResource("chpok", ofType: "mp3")
        if path == nil {
            println("Файл со звуком не найден")
            return
        }
        
        let url = NSURL(string: path!)
        
        var error: NSError?
        
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        if error != nil || audioPlayer == nil {
            println("что-то со звуком не так")
            if error != nil {
                println(error!.description);
            }
            return
        }
        
        audioPlayer!.prepareToPlay()
        
    }
    
    func startRec() -> Bool {
        if isActive {
            return true
        }
        
        var error: NSError?
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let input = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: &error) as? AVCaptureDeviceInput
        
        if input == nil {
            // по каким-то причинам мы не имеем доступ к камере, выходим
            if error != nil {
                println(error!.description)
            }
            return false
        }
        
        // меняем текст кнопки
        startStopButton.setTitle("Закончить", forState: .Normal)
        
        // настраиваем перехват и анализ видеопотока
        
        // перехват
        captureSession = AVCaptureSession()
        captureSession!.addInput(input)
        let dispatchQueue = dispatch_queue_create("barCodeQueue", nil)
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession!.addOutput(captureMetadataOutput)
        
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue:dispatchQueue)
        
        // тут я перечислил все виды бар-куар-кодов, которые поддерживаются на текущий момент
        captureMetadataOutput.metadataObjectTypes = [
            AVMetadataObjectTypeQRCode,
            AVMetadataObjectTypeUPCECode,
            AVMetadataObjectTypeCode39Code,
            AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeEAN13Code,
            AVMetadataObjectTypeEAN8Code,
            AVMetadataObjectTypeCode93Code,
            AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypePDF417Code,
            AVMetadataObjectTypeAztecCode
        ]
        
        // ну и добавляем стрим с камеры, чтобы пользователь видел что он снимает
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer!.frame = cameraView.layer.bounds
        
        cameraView.layer.addSublayer(videoPreviewLayer)
        
        // show must go on!
        captureSession!.startRunning()
        
        // ок, мы готовы
        isActive = true
        
        return true
    }
    
    func stopRec() -> Bool {
        // ну тут все очень просто:
        
        if !isActive {
            return true
        }
        
        // меняем текст кнопки
        startStopButton.setTitle("Начать", forState: .Normal)
        
        // прекращаем съемку
        captureSession!.stopRunning()
        captureSession = nil;
        
        // убираем стрим с камеры
        videoPreviewLayer!.removeFromSuperlayer()
        
        // меняем текст
        resultLabel.text = "Наведите камеру"
        
        // ок, мы завершили
        isActive = false
        
        return true
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if metadataObjects != nil && metadataObjects.count > 0 {
            let metadataObj = metadataObjects[0] as AVMetadataMachineReadableCodeObject
            
            // меняем текст надписи в основном потоке
            dispatch_async(dispatch_get_main_queue()) {
                self.resultLabel.text = metadataObj.stringValue
            }
            
            audioPlayer?.play()
        }
        
        
    }
    
    
}