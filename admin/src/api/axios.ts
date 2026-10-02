import axios from 'axios';

// 백엔드(FastAPI)와 통신하기 위한 전용 고속도로 설정
export const api = axios.create({
  baseURL: 'http://localhost:8000', // 우리가 방금 띄운 백엔드 서버 주소 고정
  headers: {
    'Content-Type': 'application/json',
  },
});