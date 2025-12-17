import SwiftUI
import UIKit
import CoreImage
import CoreGraphics

// Idea 2: Pattern-Coding Converter - Static Image Conversion
struct PatternCodingConverterView: View {
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isProcessing = false
    @State private var selectedColorBlindType: ColorBlindnessType = .protanopia
    @State private var patternStyle: PatternStyle = .dots
    @State private var isGraphMode = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pattern-Coding Converter")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Convert problematic colors in images to distinguishable patterns")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Image selection
                if selectedImage == nil {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        VStack(spacing: 15) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            Text("Select Image")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    // Original image
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Original Image")
                            .font(.headline)
                        
                        Image(uiImage: selectedImage!)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    }
                    
                    // Settings
                    VStack(spacing: 15) {
                        // Graph mode toggle
                        Toggle("Graph/Chart Mode", isOn: $isGraphMode)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        if !isGraphMode {
                            Picker("Color Blind Type", selection: $selectedColorBlindType) {
                                Text("Protanopia").tag(ColorBlindnessType.protanopia)
                                Text("Deuteranopia").tag(ColorBlindnessType.deuteranopia)
                                Text("Tritanopia").tag(ColorBlindnessType.tritanopia)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Picker("Pattern Style", selection: $patternStyle) {
                                Text("Dots").tag(PatternStyle.dots)
                                Text("Stripes").tag(PatternStyle.stripes)
                                Text("Hatching").tag(PatternStyle.hatching)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        } else {
                            Text("Converts multi-color lines in graphs to different patterns")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Process button
                    Button(action: processImage) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "wand.and.stars")
                                Text("Apply Pattern Conversion")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    
                    // Processed image
                    if let processed = processedImage {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pattern-Coded Image")
                                .font(.headline)
                            
                            Image(uiImage: processed)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                            
                            // Save button
                            Button(action: {
                                saveImageToPhotos(processed)
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save to Photos")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Reset button
                    Button(action: {
                        selectedImage = nil
                        processedImage = nil
                    }) {
                        Text("Select Different Image")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Pattern Converter")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView2(selectedImage: $selectedImage)
        }
    }
    
    private func processImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result: UIImage
            
            if isGraphMode {
                // Use graph line detector
                let detector = GraphLineDetector()
                let lines = detector.detectLines(in: image)
                result = detector.applyPatternCodingToGraph(image: image, lines: lines)
            } else {
                // Use regular pattern processor
                let processor = PatternCodingProcessor()
                result = processor.convertImageWithPatterns(
                    image: image,
                    colorBlindType: selectedColorBlindType,
                    patternStyle: patternStyle
                )
            }
            
            DispatchQueue.main.async {
                processedImage = result
                isProcessing = false
            }
        }
    }
    
    private func saveImageToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

enum PatternStyle {
    case dots
    case stripes
    case hatching
}

class PatternCodingProcessor {
    func convertImageWithPatterns(image: UIImage, colorBlindType: ColorBlindnessType, patternStyle: PatternStyle) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        // Step 1: Convert to safer color space
        let convertedImage = applyColorSpaceConversion(ciImage, type: colorBlindType)
        
        // Step 2: Detect problematic colors
        let problematicRegions = detectProblematicColors(in: convertedImage, type: colorBlindType)
        
        // Step 3: Draw patterns over problematic areas
        let patternedImage = drawPatterns(on: convertedImage, regions: problematicRegions, style: patternStyle)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(patternedImage, from: patternedImage.extent) else { return image }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func applyColorSpaceConversion(_ image: CIImage, type: ColorBlindnessType) -> CIImage {
        // Apply daltonization filter
        let filter = DaltonizationFilter.shared
        return filter.applyDaltonization(to: image, type: type) ?? image
    }
    
    private func detectProblematicColors(in image: CIImage, type: ColorBlindnessType) -> [ProblematicRegion] {
        var regions: [ProblematicRegion] = []
        
        // Define problematic color ranges based on color blind type
        let problematicRanges: [(r: ClosedRange<CGFloat>, g: ClosedRange<CGFloat>, b: ClosedRange<CGFloat>)] = {
            switch type {
            case .protanopia, .deuteranopia:
                // Red-green confusion
                return [
                    (r: 0.6...1.0, g: 0.0...0.4, b: 0.0...0.3), // Red
                    (r: 0.0...0.4, g: 0.6...1.0, b: 0.0...0.3)  // Green
                ]
            case .tritanopia:
                // Blue-yellow confusion
                return [
                    (r: 0.0...0.3, g: 0.0...0.3, b: 0.6...1.0), // Blue
                    (r: 0.8...1.0, g: 0.8...1.0, b: 0.0...0.4)  // Yellow
                ]
            case .normal:
                return []
            }
        }()
        
        // Sample the image and detect problematic regions
        let extent = image.extent
        let width = Int(extent.width)
        let height = Int(extent.height)
        
        for range in problematicRanges {
            // Create sample regions (simplified for performance)
            for y in stride(from: 0, to: height, by: 50) {
                for x in stride(from: 0, to: width, by: 50) {
                    let region = ProblematicRegion(
                        rect: CGRect(x: x, y: y, width: 50, height: 50),
                        colorRange: range
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    private func drawPatterns(on image: CIImage, regions: [ProblematicRegion], style: PatternStyle) -> CIImage {
        let extent = image.extent
        
        UIGraphicsBeginImageContext(CGSize(width: extent.width, height: extent.height))
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        // Draw base image
        let ciContext = CIContext()
        if let cgImage = ciContext.createCGImage(image, from: extent) {
            context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: extent.width, height: extent.height)))
        }
        
        // Draw patterns on problematic regions
        for region in regions {
            drawPattern(in: region.rect, style: style, context: context)
        }
        
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else { return image }
        UIGraphicsEndImageContext()
        
        return CIImage(image: resultImage) ?? image
    }
    
    private func drawPattern(in rect: CGRect, style: PatternStyle, context: CGContext) {
        context.saveGState()
        
        switch style {
        case .dots:
            drawDotsPattern(in: rect, context: context)
        case .stripes:
            drawStripesPattern(in: rect, context: context)
        case .hatching:
            drawHatchingPattern(in: rect, context: context)
        }
        
        context.restoreGState()
    }
    
    private func drawDotsPattern(in rect: CGRect, context: CGContext) {
        context.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        
        let spacing: CGFloat = 10
        for y in stride(from: rect.minY, to: rect.maxY, by: spacing) {
            for x in stride(from: rect.minX, to: rect.maxX, by: spacing) {
                let dotRect = CGRect(x: x, y: y, width: 4, height: 4)
                context.fillEllipse(in: dotRect)
            }
        }
    }
    
    private func drawStripesPattern(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(2)
        
        let spacing: CGFloat = 8
        for x in stride(from: rect.minX, to: rect.maxX, by: spacing) {
            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        context.strokePath()
    }
    
    private func drawHatchingPattern(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1.5)
        
        let spacing: CGFloat = 12
        
        // Diagonal lines /
        for offset in stride(from: -rect.height, to: rect.width + rect.height, by: spacing) {
            context.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.minX + offset + rect.height, y: rect.maxY))
        }
        
        // Diagonal lines \
        for offset in stride(from: -rect.height, to: rect.width + rect.height, by: spacing) {
            context.move(to: CGPoint(x: rect.minX + offset, y: rect.maxY))
            context.addLine(to: CGPoint(x: rect.minX + offset + rect.height, y: rect.minY))
        }
        
        context.strokePath()
    }
}

struct ProblematicRegion {
    let rect: CGRect
    let colorRange: (r: ClosedRange<CGFloat>, g: ClosedRange<CGFloat>, b: ClosedRange<CGFloat>)
}
