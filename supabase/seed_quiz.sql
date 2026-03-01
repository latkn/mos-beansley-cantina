-- Примеры вопросов для подбора напитка (выполнить после schema.sql)
-- При повторном запуске будут дубликаты — при необходимости: delete from quiz_answers; delete from quiz_questions;

insert into quiz_questions (text, is_active, weight, sort_order) values
  ('Какой уровень сладости предпочитаете?', true, 1, 0),
  ('Насколько интенсивный вкус вам по душе?', true, 1, 1),
  ('Готовы к нестандартным сочетаниям (пряности, чили, необычные добавки)?', true, 1.2, 2);

-- Ответы к вопросу 1 (сладость)
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Без сладости, горький кофе', -2, 2, 1, 0, 0 from quiz_questions where text = 'Какой уровень сладости предпочитаете?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Нейтрально', 0, 0, 0, 0, 1 from quiz_questions where text = 'Какой уровень сладости предпочитаете?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Сладковатый, с сиропом или молоком', 2, -1, -1, 0, 2 from quiz_questions where text = 'Какой уровень сладости предпочитаете?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Очень сладкий, десертный', 3, -2, -1, 1, 3 from quiz_questions where text = 'Какой уровень сладости предпочитаете?' limit 1;

-- Ответы к вопросу 2 (интенсивность)
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Мягкий, лёгкий', 0, -1, -2, -1, 0 from quiz_questions where text = 'Насколько интенсивный вкус вам по душе?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Средний', 0, 0, 0, 0, 1 from quiz_questions where text = 'Насколько интенсивный вкус вам по душе?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Насыщенный, крепкий', 0, 1, 2, 0, 2 from quiz_questions where text = 'Насколько интенсивный вкус вам по душе?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Максимально бодрящий', 0, 2, 3, 2, 3 from quiz_questions where text = 'Насколько интенсивный вкус вам по душе?' limit 1;

-- Ответы к вопросу 3 (экстрим)
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Только классика: эспрессо, американо, латте', 0, 0, 0, -2, 0 from quiz_questions where text = 'Готовы к нестандартным сочетаниям (пряности, чили, необычные добавки)?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Можно что-то с пряностями или необычным вкусом', 0, 0, 0, 1, 1 from quiz_questions where text = 'Готовы к нестандартным сочетаниям (пряности, чили, необычные добавки)?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Да, хочу попробовать чили, имбирь, том-ям и т.п.', 0, 1, 2, 4, 2 from quiz_questions where text = 'Готовы к нестандартным сочетаниям (пряности, чили, необычные добавки)?' limit 1;
