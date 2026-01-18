1.เข้ามา สร้าง db postgrasql ชื่อ MuMood
2. cd backend
2. รันสำสั่ง pip install -r requirements.txt
3. เเก้ รหัส postgrasql เป็นของตัวเอง
4. รัน alembic upgrade head
5. เปิดดูตารางว่ามีขึ้นมั้ย
6. รัน backend ใช้ uvicorn app.main:app --reload
7. เข้าลิง http://localhost:8000/docs เทส swagger 