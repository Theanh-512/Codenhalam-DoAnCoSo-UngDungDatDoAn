import os

pdf_path = r"d:\DoAnCoSo\DOANCOSO\Codenhalam-DoAnCoSo-UngDungDatDoAn\Database\Tái cấu trúc Cơ sở Lý thuyết Đồ án.pdf"
output_path = r"scratch\pdf_text_extracted.txt"

print(f"Checking for PDF at: {pdf_path}")
if not os.path.exists(pdf_path):
    print("❌ PDF file not found!")
    exit(1)

extracted = False

# Try pypdf
if not extracted:
    try:
        import pypdf
        print("Using pypdf...")
        reader = pypdf.PdfReader(pdf_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(text)
        print("✅ Extracted using pypdf!")
        extracted = True
    except ImportError:
        print("pypdf not installed.")
    except Exception as e:
        print(f"Error with pypdf: {e}")

# Try pdfplumber
if not extracted:
    try:
        import pdfplumber
        print("Using pdfplumber...")
        with pdfplumber.open(pdf_path) as pdf:
            text = ""
            for page in pdf.pages:
                text += page.extract_text() + "\n"
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(text)
        print("✅ Extracted using pdfplumber!")
        extracted = True
    except ImportError:
        print("pdfplumber not installed.")
    except Exception as e:
        print(f"Error with pdfplumber: {e}")

# Try fitz (PyMuPDF)
if not extracted:
    try:
        import fitz
        print("Using fitz...")
        doc = fitz.open(pdf_path)
        text = ""
        for page in doc:
            text += page.get_text() + "\n"
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(text)
        print("✅ Extracted using fitz!")
        extracted = True
    except ImportError:
        print("fitz not installed.")
    except Exception as e:
        print(f"Error with fitz: {e}")

if not extracted:
    print("No pdf extraction library found. Attempting to install pypdf...")
    try:
        import subprocess
        subprocess.check_call(["pip", "install", "pypdf"])
        import pypdf
        reader = pypdf.PdfReader(pdf_path)
        text = ""
        for page in reader.pages:
            t = page.extract_text()
            if t:
                text += t + "\n"
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(text)
        print("✅ Extracted successfully after installing pypdf!")
        extracted = True
    except Exception as e:
        print(f"Failed to install and extract: {e}")
