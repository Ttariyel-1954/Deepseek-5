const axios = require('axios');
const aiService = require('../../src/services/aiService');

describe('aiService (mock mode)', () => {
  let axiosPostSpy;
  const originalMode = process.env.AI_MODE;

  beforeEach(() => {
    process.env.AI_MODE = 'mock';
    // Real API-nin çağırılmadığını yoxlamaq üçün axios.post-u izləyirik
    axiosPostSpy = jest.spyOn(axios, 'post').mockResolvedValue({ data: {} });
  });

  afterEach(() => {
    axiosPostSpy.mockRestore();
    process.env.AI_MODE = originalMode;
  });

  test('callAI (deepseek provider) — mock JSON qaytarır, real API çağırılmır', async () => {
    const result = await aiService.callAI('Büdcə proqnozu üçün prompt', {
      provider: 'deepseek',
      model: 'deepseek-chat',
      teyinat_novu: 'budce_prognozu',
    });

    expect(result.mode).toBe('mock');
    expect(result.provider).toBe('deepseek');
    expect(result.data).toBeInstanceOf(Object);
    expect(result.data.prognoz_budce).toBeDefined();
    expect(result.data.sapma_faizi).toBeDefined();
    expect(axiosPostSpy).not.toHaveBeenCalled();
  });

  test('callAI (anthropic provider) — mock JSON qaytarır, real API çağırılmır', async () => {
    const result = await aiService.callAI('Risk analizi üçün prompt', {
      provider: 'anthropic',
      model: 'claude-sonnet-5',
      teyinat_novu: 'risk_analizi',
    });

    expect(result.mode).toBe('mock');
    expect(result.provider).toBe('anthropic');
    expect(result.data).toBeInstanceOf(Object);
    expect(result.data.kritik_risk).toBeDefined();
    expect(result.data.mudaxile_plani).toBeDefined();
    expect(axiosPostSpy).not.toHaveBeenCalled();
  });
});
