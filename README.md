# MuMood — Music Review & Discovery Platform

แพลตฟอร์มสำหรับค้นหาและรีวิวเพลง เชื่อมต่อ Spotify API ให้ผู้ใช้บันทึกความรู้สึกต่อเพลงในหลายมิติและจัดการเพลงโปรดในที่เดียว

<br>

## Features

**1. Authentication**
&nbsp;&nbsp;&nbsp;&nbsp;หน้า Login / Register มีแถบสลับโหมดด้านบน รองรับการกรอก Username หรือ Email พร้อม Password ที่ซ่อนตัวอักษร มีตัวเลือก Remember me และช่อง Confirm Password ในโหมดสมัครสมาชิก

**2. Home & Discovery**
&nbsp;&nbsp;&nbsp;&nbsp;แถบค้นหาสำหรับชื่อเพลงและศิลปิน ดึงข้อมูลจาก Spotify API กดปกเพลงเพื่อเข้าหน้ารีวิวได้ทันที มีแถบ Filter สำหรับเลือกประเภทเพลง

**3. Review**
&nbsp;&nbsp;&nbsp;&nbsp;แสดงปกขนาดใหญ่พร้อมชื่อเพลงและศิลปิน
- `Multi Rating` — Slider แยก 3 มิติ ได้แก่ Beat (จังหวะดนตรี), Lyric (เนื้อเพลง) และ Mood (อารมณ์ร่วม)
- `Emotion Selector` — เลือก Emotion tag ที่สื่อถึงความรู้สึกที่มีต่อเพลง เช่น Happy, Sad, Angry, Chill
- `Mood Color Palette` — เลือกสีอารมณ์ของเพลง สีที่เลือกจะเปลี่ยน Background ของหน้าแบบ real-time
- `Comment` — แสดงความคิดเห็นของผู้ใช้อื่น พร้อมปุ่มเขียนรีวิวของตัวเอง

**4. History**
&nbsp;&nbsp;&nbsp;&nbsp;รายการรีวิวทั้งหมดในรูปแบบ List แสดงข้อมูลผู้ใช้และจำนวนรีวิวรวม แต่ละการ์ดประกอบด้วย Thumbnail ชื่อเพลง ศิลปิน คะแนน Beat/Lyric/Mood Emotion ที่เลือก และข้อความรีวิว

**5. Favorite Songs**
&nbsp;&nbsp;&nbsp;&nbsp;Gallery รูปแบบ Grid เน้นปกอัลบั้ม แต่ละรายการแสดงปก ชื่อเพลง ไอคอนหัวใจ และชื่อศิลปิน

**6. User Profile**
&nbsp;&nbsp;&nbsp;&nbsp;แสดง Avatar, Username และ Email พร้อมสถิติภาพรวม ได้แก่ จำนวน Reaction ที่ได้รับ, จำนวนรีวิวทั้งหมด และวันที่สร้างบัญชี มีปุ่ม Log out

<br>

## Admin

**7. Home Admin**
&nbsp;&nbsp;&nbsp;&nbsp;Toggle Menu กรองเพลงใน 3 โหมด ได้แก่ ทั้งหมด, จาก Spotify และที่แอดมินเพิ่มเอง รองรับการแสดงผล 2 รูปแบบ ได้แก่ Grid และ List สลับได้จากปุ่ม Toggle มุมบนขวา

**8. Manage Song**
&nbsp;&nbsp;&nbsp;&nbsp;แอดมินจัดการเพลง Custom ในระบบได้ครบ 3 ฟังก์ชัน ได้แก่ เพิ่ม, แก้ไข และลบ การเพิ่มเพลงรองรับการกรอกข้อมูล ได้แก่ ปกเพลง, ชื่อเพลง, ประเภทเพลง, ชื่ออัลบั้ม, ชื่อศิลปิน และลิงก์สำหรับเชื่อมต่อไปยังแหล่งฟังภายนอก
