//
//  ColorContrastEnhancer.swift
//  Colourblind Camera
//
//  Enhanced contrast filtering for different types of color blindness
//

import CoreImage
import UIKit
import Vision

class ColorContrastEnhancer {
    static let shared = ColorContrastEnhancer()
    private let context = CIContext()
    
    enum ContrastMode {
        case normal
        case highContrast
        case trafficLight
        case readingMode
        case navigationMode
    }
    
    func enhanceContrast(for image: CIImage, colorBlindType: ColorBlindnessType, mode: ContrastMode) -> CIImage? {
        switch mode {
        case .normal:
            return applyBasicContrast(to: image, colorBlindType: colorBlindType)
        case .highContrast:
            return applyHighContrast(to: image, colorBlindType: colorBlindType)
        case .trafficLight:
            return enhanceTrafficLightColors(to: image, colorBlindType: colorBlindType)
        case .readingMode:
            return applyReadingModeContrast(to: image, colorBlindType: colorBlindType)
        case .navigationMode:
            return enhanceNavigationColors(to: image, colorBlindType: colorBlindType)
        }
    }
    
    private func applyBasicContrast(to image: CIImage, colorBlindType: ColorBlindnessType) -> CIImage? {
        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(image, forKey: kCIInputImageKey)
        
        switch colorBlindType {
        case .protanopia, .deuteranopia:
            contrastFilter?.setValue(1.3, forKey: kCIInputContrastKey)
            contrastFilter?.setValue(1.1, forKey: kCIInputSaturationKey)
        case .tritanopia:
            contrastFilter?.setValue(1.2, forKey: kCIInputContrastKey)
            contrastFilter?.setValue(1.2, forKey: kCIInputSaturationKey)
        case .normal:
            return image
        }
        
        return contrastFilter?.outputImage
    }
    
    private func applyHighContrast(to image: CIImage, colorBlindType: ColorBlindnessType) -> CIImage? {
        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(image, forKey: kCIInputImageKey)
        contrastFilter?.setValue(1.8, forKey: kCIInputContrastKey)
        contrastFilter?.setValue(1.4, forKey: kCIInputSaturationKey)
        contrastFilter?.setValue(0.1, forKey: kCIInputBrightnessKey)
        
        return contrastFilter?.outputImage
    }
    
    private func enhanceTrafficLightColors(to image: CIImage, colorBlindType: ColorBlindnessType) -> CIImage? {
        // Specific enhancement for red/green traffic lights
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        
        switch colorBlindType {
        case .protanopia, .deuteranopia:
            // Enhance red and green differentiation
            filter.setValue(CIVector(x: 1.5, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
            filter.setValue(CIVector(x: 0.0, y: 1.8, z: 0.0, w: 0.0), forKey: "inputGVector")
            filter.setValue(CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0), forKey: "inputBVector")
        case .tritanopia:
            // Enhance blue/yellow differentiation
            filter.setValue(CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
            filter.setValue(CIVector(x: 0.0, y: 1.2, z: 0.0, w: 0.0), forKey: "inputGVector")
            filter.setValue(CIVector(x: 0.0, y: 0.0, z: 1.6, w: 0.0), forKey: "inputBVector")
        case .normal:
            return image
        }
        
        return filter.outputImage
    }
    
    private func applyReadingModeContrast(to image: CIImage, colorBlindType: ColorBlindnessType) -> CIImage? {
        // Optimize for text reading
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(1.4, forKey: kCIInputContrastKey)
        filter?.setValue(0.8, forKey: kCIInputSaturationKey)
        filter?.setValue(0.05, forKey: kCIInputBrightnessKey)
        
        return filter?.outputImage
    }
    
    private func enhanceNavigationColors(to image: CIImage, colorBlindType: ColorBlindnessType) -> CIImage? {
        // Optimize for map and navigation viewing
        let vibrance = CIFilter(name: "CIVibrance")
        vibrance?.setValue(image, forKey: kCIInputImageKey)
        vibrance?.setValue(0.3, forKey: kCIInputAmountKey)
        
        return vibrance?.outputImage
    }
}