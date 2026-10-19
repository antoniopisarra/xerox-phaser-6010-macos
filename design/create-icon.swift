import Cocoa
let output=CommandLine.arguments[1]
let image=NSImage(size:NSSize(width:1024,height:1024))
image.lockFocus()
let bg=NSBezierPath(roundedRect:NSRect(x:64,y:64,width:896,height:896),xRadius:200,yRadius:200)
NSGradient(starting:NSColor(calibratedRed:0.05,green:0.27,blue:0.39,alpha:1),ending:NSColor(calibratedRed:0.07,green:0.66,blue:0.70,alpha:1))!.draw(in:bg,angle:55)
func rect(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat,_ radius:CGFloat,_ color:NSColor){color.setFill();NSBezierPath(roundedRect:NSRect(x:x,y:y,width:w,height:h),xRadius:radius,yRadius:radius).fill()}
rect(304,612,416,220,26,NSColor(white:0.97,alpha:1))
rect(352,739,246,16,8,NSColor(white:0.78,alpha:1));rect(352,695,310,16,8,NSColor(white:0.85,alpha:1))
NSGraphicsContext.saveGraphicsState()
let shadow=NSShadow();shadow.shadowColor=NSColor.black.withAlphaComponent(0.24);shadow.shadowOffset=NSSize(width:0,height:-17);shadow.shadowBlurRadius=26;shadow.set()
rect(176,338,672,326,68,NSColor(white:0.91,alpha:1))
NSGraphicsContext.restoreGraphicsState()
rect(218,538,588,83,28,NSColor(calibratedRed:0.12,green:0.25,blue:0.32,alpha:1))
rect(678,560,63,19,9,NSColor(calibratedRed:0.18,green:0.88,blue:0.70,alpha:1))
rect(270,363,484,45,18,NSColor(calibratedRed:0.14,green:0.27,blue:0.34,alpha:1))
rect(304,193,416,209,23,NSColor.white)
for (i,color) in [NSColor.systemCyan,NSColor.systemPink,NSColor.systemYellow,NSColor(calibratedWhite:0.2,alpha:1)].enumerated(){rect(CGFloat(351+i*83),286,57,16,8,color)}
rect(351,244,300,12,6,NSColor(calibratedWhite:0.83,alpha:1))
image.unlockFocus()
let bitmap=NSBitmapImageRep(data:image.tiffRepresentation!)!
try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:output))
