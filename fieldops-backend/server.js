const express = require('express');
const multer = require('multer');
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Set up storage for uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.fieldname}.png`);
  }
});

const upload = multer({ storage });

// Ensure output directory exists
const pdfDir = path.join(__dirname, 'generated_pdfs');
if (!fs.existsSync(pdfDir)) fs.mkdirSync(pdfDir);

// POST Endpoint to receive site sheet & generate PDF
app.post('/api/work-orders/submit', upload.fields([
  { name: 'checkInFace', maxCount: 1 },
  { name: 'checkOutFace', maxCount: 1 },
  { name: 'beforePhoto', maxCount: 1 },
  { name: 'afterPhoto', maxCount: 1 },
  { name: 'signature', maxCount: 1 }
]), (req, res) => {
  try {
    const {
      clientName,
      scope,
      gpsCoords,
      checkInTime,
      checkOutTime,
      totalDuration,
      materialsUsed
    } = req.body;

    const materials = materialsUsed ? JSON.parse(materialsUsed) : [];
    const workOrderId = `WO-${Date.now().toString().slice(-6)}`;
    const pdfPath = path.join(pdfDir, `${workOrderId}.pdf`);

    // 1. Initialize A4 Document
    const doc = new PDFDocument({ margin: 40, size: 'A4' });
    const writeStream = fs.createWriteStream(pdfPath);
    doc.pipe(writeStream);

    // 2. Header & Branding
    doc.rect(0, 0, 595.28, 70).fill('#0B132B');
    doc.fillColor('#FFFFFF').fontSize(18).font('Helvetica-Bold').text('FIELDOPS ENTERPRISE', 40, 20);
    doc.fontSize(10).font('Helvetica').text('SITE SERVICE VERIFICATION & PROOF OF WORK', 40, 42);
    doc.fontSize(10).text(`DISPATCH ID: ${workOrderId}`, 420, 25);
    doc.text(`DATE: ${new Date().toLocaleDateString('en-GB')}`, 420, 40);

    // 3. Project & Site Details
    doc.moveDown(3);
    doc.fillColor('#0F172A').fontSize(12).font('Helvetica-Bold').text('1. SITE & CUSTOMER PARTICULARS');
    doc.rect(40, doc.y, 515, 1).fill('#E2E8F0');
    doc.moveDown(0.5);

    doc.fontSize(10).font('Helvetica-Bold').text('Client / Site Name: ', 40, doc.y, { continued: true })
       .font('Helvetica').text(clientName || 'N/A');
    doc.font('Helvetica-Bold').text('Scope of Rectification: ', 40, doc.y + 4, { continued: true })
       .font('Helvetica').text(scope || 'N/A');
    doc.font('Helvetica-Bold').text('Verified GPS Coordinates: ', 40, doc.y + 4, { continued: true })
       .font('Helvetica').text(gpsCoords || 'N/A');

    // 4. Biometric Attendance Matrix
    doc.moveDown(1.5);
    doc.font('Helvetica-Bold').fontSize(12).text('2. BIOMETRIC ATTENDANCE & ON-SITE AUDIT');
    doc.rect(40, doc.y, 515, 1).fill('#E2E8F0');
    doc.moveDown(0.5);

    const checkInPath = req.files['checkInFace'] ? req.files['checkInFace'][0].path : null;
    const checkOutPath = req.files['checkOutFace'] ? req.files['checkOutFace'][0].path : null;

    let imgY = doc.y + 5;
    if (checkInPath) {
      doc.image(checkInPath, 40, imgY, { width: 65, height: 65 });
      doc.fontSize(9).font('Helvetica-Bold').text('Arrival Face', 40, imgY + 70);
      doc.font('Helvetica').text(checkInTime || 'N/A', 40, imgY + 82);
    }

    if (checkOutPath) {
      doc.image(checkOutPath, 160, imgY, { width: 65, height: 65 });
      doc.fontSize(9).font('Helvetica-Bold').text('Departure Face', 160, imgY + 70);
      doc.font('Helvetica').text(checkOutTime || 'N/A', 160, imgY + 82);
    }

    doc.rect(300, imgY, 255, 95).fill('#F8FAFC');
    doc.fillColor('#0F172A').fontSize(10).font('Helvetica-Bold').text('LABOR & SITE CHRONO', 315, imgY + 15);
    doc.fontSize(9).font('Helvetica').text(`Total Duration On-Site: ${totalDuration || 'N/A'}`, 315, imgY + 35);
    doc.text(`Compliance: DOSH / OSHA Standards Verified`, 315, imgY + 52);
    doc.text(`Status: Geo-Stamped Work Complete`, 315, imgY + 69);

    // 5. Photographic Evidence
    doc.y = imgY + 115;
    doc.fillColor('#0F172A').fontSize(12).font('Helvetica-Bold').text('3. SITE PHOTO EVIDENCE (BEFORE & AFTER)');
    doc.rect(40, doc.y, 515, 1).fill('#E2E8F0');
    doc.moveDown(0.5);

    const beforePhotoPath = req.files['beforePhoto'] ? req.files['beforePhoto'][0].path : null;
    const afterPhotoPath = req.files['afterPhoto'] ? req.files['afterPhoto'][0].path : null;
    const photoY = doc.y + 5;

    if (beforePhotoPath) {
      doc.image(beforePhotoPath, 40, photoY, { width: 240, height: 135 });
      doc.fontSize(9).font('Helvetica-Bold').text('BEFORE RECTIFICATION', 40, photoY + 140);
    }
    if (afterPhotoPath) {
      doc.image(afterPhotoPath, 310, photoY, { width: 240, height: 135 });
      doc.fontSize(9).font('Helvetica-Bold').text('AFTER RECTIFICATION', 310, photoY + 140);
    }

    // 6. Materials Consumed & Sign-off (Page 2)
    doc.addPage();
    doc.fillColor('#0F172A').fontSize(12).font('Helvetica-Bold').text('4. MOBILE WAREHOUSE / BILLABLE MATERIALS');
    doc.rect(40, doc.y, 515, 1).fill('#E2E8F0');
    doc.moveDown(0.5);

    let totalMaterialSum = 0;
    materials.forEach((item) => {
      const lineTotal = item.unitPrice * item.quantity;
      totalMaterialSum += lineTotal;
      doc.fontSize(9).font('Helvetica').text(`${item.title} (${item.sku})`, 40, doc.y + 3);
      doc.text(`Qty: ${item.quantity} x RM ${item.unitPrice.toFixed(2)}`, 350, doc.y - 12);
      doc.font('Helvetica-Bold').text(`RM ${lineTotal.toFixed(2)}`, 480, doc.y - 12, { align: 'right' });
    });

    doc.moveDown(1);
    doc.font('Helvetica-Bold').fontSize(11).text(`TOTAL MATERIALS (EXCL. SST): RM ${totalMaterialSum.toFixed(2)}`, { align: 'right' });

    // 7. Customer Sign-off Deck
    doc.moveDown(2);
    doc.fillColor('#0F172A').fontSize(12).font('Helvetica-Bold').text('5. AUTHORIZED CUSTOMER ACCEPTANCE');
    doc.rect(40, doc.y, 515, 1).fill('#E2E8F0');
    doc.moveDown(1);

    const sigPath = req.files['signature'] ? req.files['signature'][0].path : null;
    if (sigPath) {
      doc.image(sigPath, 40, doc.y, { width: 160, height: 75 });
      doc.moveDown(4.5);
      doc.fontSize(9).font('Helvetica').text('I hereby confirm the works detailed above have been satisfactorily completed.', 40, doc.y);
      doc.text(`Signatory Acknowledgement: Authorized On-Site Representative`, 40, doc.y + 14);
    }

    // Finalize
    doc.end();

    writeStream.on('finish', () => {
      res.json({
        success: true,
        message: 'PDF Work Order Generated Successfully',
        workOrderId,
        downloadUrl: `/api/work-orders/${workOrderId}/download`
      });
    });

  } catch (err) {
    console.error('PDF Generation Failure:', err);
    res.status(500).json({ error: 'Server error compiling site work order' });
  }
});

// Endpoint to stream/download generated PDF
app.get('/api/work-orders/:id/download', (req, res) => {
  const filePath = path.join(pdfDir, `${req.params.id}.pdf`);
  if (fs.existsSync(filePath)) {
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=${req.params.id}.pdf`);
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.status(404).send('PDF not found');
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[FieldOps Engine] Running on port ${PORT}`);
});