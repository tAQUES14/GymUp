import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
})

// Injeta Bearer token e corrige Content-Type para uploads multipart
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  // Quando o body é FormData, remove o Content-Type fixo para que o
  // browser defina automaticamente "multipart/form-data; boundary=..."
  // com o boundary correto — essencial para uploads de arquivo.
  if (config.data instanceof FormData) {
    delete config.headers['Content-Type']
  }

  return config
})

// Redireciona para /login em caso de 401
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('admin_token')
      localStorage.removeItem('admin_user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
