# MuMood — Music Review & Discovery Platform

แพลตฟอร์มสำหรับค้นหาและรีวิวเพลง เชื่อมต่อ Spotify API ให้ผู้ใช้บันทึกความรู้สึกต่อเพลงในหลายมิติและจัดการเพลงโปรดในที่เดียว

<br>

## Features

**1. Authentication**
&nbsp;&nbsp;&nbsp;&nbsp;หน้า Login / Register มีแถบสลับโหมดด้านบน รองรับการกรอก Username หรือ Email พร้อม Password ที่ซ่อนตัวอักษร เเละเรื่องเเนวเพลงที่ชื่นชอบ ในโหมดสมัครสมาชิก มีตัวเลือก Remember me 

**2. Home & Discovery**
&nbsp;&nbsp;&nbsp;&nbsp;แถบค้นหาสำหรับชื่อเพลงและศิลปิน ดึงข้อมูลจาก Spotify API กดปกเพลงเพื่อเข้าหน้ารีวิวได้ทันที ิเเละมีส่วนในการ Filter สำหรับเลือกประเภทเพลง

**3. Review**
&nbsp;&nbsp;&nbsp;&nbsp;แสดงปกขนาดใหญ่พร้อมชื่อเพลงและศิลปิน
- `Preview audioplayer demo` — เพื่อให้ผู้ใช้สามารถฟัง demo เพลง 30 วิ ก่อนทำการทำงานรีวิว
- `Emotion Selector` — เลือก Emotion tag ที่สื่อถึงความรู้สึกที่มีต่อเพลง เช่น Happy, Sad
- `Multi Rating` — Slider แยก 3 มิติ ได้แก่ Beat (จังหวะดนตรี), Lyric (เนื้อเพลง) และ Mood (อารมณ์ร่วม)
- `Mood Color Palette` — เลือกสีอารมณ์ของเพลง สีที่เลือกจะเปลี่ยน Background ของหน้าแบบ real-time
- `Comment` — แสดงความคิดเห็นของผู้ใช้อื่น พร้อมปุ่มเขียนรีวิวของตัวเอง

**4. History**
&nbsp;&nbsp;&nbsp;&nbsp;รายการรีวิวทั้งหมดในรูปแบบ List แสดงข้อมูลผู้ใช้ที่ได้ทำทั้งหมดในแอปพิเคชั่น

**5. Favorite Songs**
&nbsp;&nbsp;&nbsp;&nbsp;Gallery รูปแบบ Grid เน้นปกอัลบั้ม แต่ละรายการแสดงปก ชื่อเพลง ไอคอนหัวใจ และชื่อศิลปิน

**6. User Profile**
&nbsp;&nbsp;&nbsp;&nbsp;แสดง Avatar,  Email พร้อมสถิติภาพรวม ได้แก่ จำนวนรีวิวทั้งหมด และมีปุ่ม Log out

<br>

## Admin

**7. Home Admin**
&nbsp;&nbsp;&nbsp;&nbsp;Toggle Menu กรองเพลงใน 3 โหมด ได้แก่ ทั้งหมด, จาก Spotify และที่แอดมินเพิ่มเอง รองรับการแสดงผล 2 รูปแบบ ได้แก่ Grid และ List สลับได้จากปุ่ม Toggle มุมบนขวา

**8. Manage Song**
&nbsp;&nbsp;&nbsp;&nbsp;แอดมินจัดการเพลง Custom ในระบบได้ครบ 3 ฟังก์ชัน ได้แก่ เพิ่ม, แก้ไข และลบ การเพิ่มเพลงรองรับการกรอกข้อมูล ได้แก่ ปกเพลง, ชื่อเพลง, ประเภทเพลง, ชื่ออัลบั้ม, ชื่อศิลปิน และลิงก์สำหรับเชื่อมต่อไปยังแหล่งฟังภายนอก



# Setup Backend สำหรับรัน

## ความต้องการของระบบ
- Python 3.8+
- PostgreSQL
- pip

## ขั้นตอนการติดตั้ง

### 1. ติดตั้ง Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 2. ตั้งค่า Environment Variables
สร้างไฟล์ `.env` ใน folder `backend/` แล้วใส่:
```
DATABASE_URL="postgresql+asyncpg://[username]:[password]a@localhost:5432/MuMood"
SECRET_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
SPOTIFY_CLIENT_ID = 'xxxxxxxxxxx'
SPOTIFY_CLIENT_SECRET = 'xxxxxxxxxxxxxx'
```

### 3. Setup PostgreSQL Database
ติดตั้ง PostgreSQL และสร้าง database

รัน migration:
```bash
cd backend
alembic revision --autogenerate -m "set up database"
alembic upgrade head
```

### 4. นำเข้าข้อมูลเริ่มต้น
```bash
python seed.py
```

### 5. รัน Backend Server
```bash
uvicorn app.main:app --reload
```

Backend จะรันที่ http://localhost:8000

### 6. ทดสอบ API
เปิดเว็บเบราว์เซอร์:
- http://localhost:8000/docs (API Documentation)
- http://localhost:8000 (หน้าหลัก)

## หยุดการทำงาน
กด `Ctrl + C` ใน Terminal
