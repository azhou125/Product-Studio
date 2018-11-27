//
//  BoundingBoxView.swift
//

import UIKit

class BoundingBoxView: UIView
{
    let BoundingBoxLineWidth = 7
    var boxesToBeErased : [TensorflowPrediction] = []
    var boxesToBeDrawn  : [TensorflowPrediction] = []
    var labels          : [UILabel]              = []
        
    //
    // in drawRect we have a clear UIView that we draw green bounding boxes in.
    // As a new list of boundingboxes comes in we erase the old boxes and draw the new ones.
    // Since this view is just a layer over the videoPreview the bounding boxes could be a few
    // frames behind and the box will not align with the object underneath it.  This will likely
    // be an issue until Tensorflow processing is as fast as the video preview's frame capture.
    //
    override func draw(_ rect: CGRect)
    {
        //
        // Our drawing context
        //
        if let context:CGContext = UIGraphicsGetCurrentContext() {
            
            //
            // The width of the bounding box lines.
            //
            context.setLineWidth(CGFloat(BoundingBoxLineWidth));
            
            //
            // The fill color of the bounding box is always clear
            //
            context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
            
            //
            // Erase boxes from the previous frame
            //
            if (!self.boxesToBeErased.isEmpty)
            {
                for pred:TensorflowPrediction in self.boxesToBeErased
                {
                    // Erase the previous bounding box by using a clear stroke color
                    context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
                    
                    // Calculate box dimensions of box to be erased.
                    let x =  CGFloat(pred.left)   * self.frame.size.width
                    let y =  CGFloat(pred.top)    * self.frame.size.height
                    let w = (CGFloat(pred.right)  * self.frame.size.width)  - x
                    let h = (CGFloat(pred.bottom) * self.frame.size.height) - y
                    let rectangle:CGRect = CGRect(x: x, y: y, width: w, height: h)
                    
                    //Erase it. (draw clear pixels over the green)
                    context.fill(rectangle)
                    context.stroke(rectangle)
                }
                
                //
                // Remove existing labels too.
                //
                for label in labels
                {
                    label.removeFromSuperview()
                }
                
                self.labels.removeAll()
                self.boxesToBeErased.removeAll()
            }
            
            //
            // Draw newly predicted boxes
            //
            for pred:TensorflowPrediction in boxesToBeDrawn {
                //
                // Calculate the box dimensions.  The box dimensions are given
                // as normalized values. Because this view has the same dimensions
                // as the original image multiplying by width and height gives the
                // correct location for the bounding box.
                //
                let x = CGFloat(pred.left)   * self.frame.size.width;
                let y = CGFloat(pred.top)    * self.frame.size.height;
                let w = (CGFloat(pred.right) * self.frame.size.width)  - x;
                let h = (CGFloat(pred.bottom) * self.frame.size.height) - y;
                let rectangle = CGRect(x: x, y: y, width: w, height: h)
                
                
                // Add the label to the upper left of the bounding box
                let label:UILabel = UILabel(frame: CGRect(x: x, y: y, width: 100, height: 55))
                label.backgroundColor = UIColor.white
                label.textColor = UIColor.orange
                label.text = String(format: "%@ %.1f%%", pred.label, pred.score * 100)
                label.sizeToFit()
//                label.font = label.font.withSize(16)
                self.addSubview(label)
                
                // get freshness level and convert to float.
                var labelText = pred.label
                let labelTextArr = labelText!.characters.split{$0 == " "}.map(String.init)
                
                let conv = (labelTextArr[1] as NSString).floatValue
            
                // Draw with a green stroke.
                context.setStrokeColor(red: 0.0, green: CGFloat(0.5 + conv / 6.0), blue: CGFloat(1 - conv / 3.0), alpha: 0.75)
                context.fill(rectangle)
                context.stroke(rectangle)

                //
                // Keep a list of labels so we can easily remove from superview.
                //
                labels.append(label)
            }
        }
    }
    
    func updateBoundingBoxes(_ boxes:[TensorflowPrediction])
    {
        //
        // flag the old boxes to be erased and flag the new to be drawn.
        //
        self.boxesToBeErased = self.boxesToBeDrawn;
        self.boxesToBeDrawn = boxes;
        
        //
        // trigger a drawRect call next frame
        //
        self.setNeedsDisplay()
    }
}
