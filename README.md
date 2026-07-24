# OptmWiz

**Machine Learning Prototype for Price Optimization using Random Forests**

OptmWiz is a Shiny application that demonstrates how predictive analytics can be applied to optimize material and labour pricing.  
It is hosted as a **prototype demo** — users can interact with the app using the provided sample dataset, but the tool is not intended for download or reuse.

---

## 👥 Authors & Citation
* **Prasanth V P and Midhu N N**
* Contact/E-mail: prasanth.stat@gmail.com

---

## 📖 Problem Statement

A logistics and construction services company (dummy name: **BuildSmart Inc.**) faced a recurring challenge:  
customers often requested multiple quotes for materials and labour, but only some were accepted.  
Even within itemized “one stop one shop” quotes, parts of the proposal were rejected.  
This inconsistency made it difficult to predict revenue and optimize pricing strategies.

---

## 🎯 Business Challenge

- **Quick Quotes** were frequently generated but rarely converted into formal orders.  
- Some customers appeared to use Quick Quotes to benchmark against competitors.  
- Certain materials (e.g., Asphalt) showed systematic rejection patterns.  
- Draft quotes were irrelevant since they were never shared externally.  

BuildSmart needed a way to **predict acceptance probability** for each quote, helping them focus on profitable bids and reduce wasted effort.

---

## 💡 Solution Approach

OptmWiz applies **Random Forest classification** to historical quote data to predict whether a quote is likely to be accepted or rejected.  

- **Exploratory Data Analysis (EDA):** Aggregated quotes by customer, material, supplier, task type, truck type, and costs.  
- **Feature Engineering:** Standardized costs (per load), aggregated averages (material, labour, total, per mile/minute).  
- **Modeling:** Used decision trees and Random Forests to identify influential variables (material, supplier, truck type).  
- **Prediction:** Classified quotes into “likely accepted” vs. “likely rejected” with probability thresholds (≥ 0.5).  
- **Validation:** Confusion matrices and accuracy checks confirmed predictive adequacy (~75–80% accuracy).  

---

## 🔬 Statistical Depth

- **Recursive Partitioning & Regression Trees (rpart):** Initial variable importance analysis.  
- **Random Forests:** Robust ensemble learning to handle noisy Quick Quote data.  
- **Model Adequacy Checks:** Train/test splits (Pareto 80–20 principle), confusion matrices, accuracy metrics.  
- **Business Interpretation:** Material emerged as the strongest predictor of acceptance, followed by supplier and truck type.  

---

## 🖥️ Application Layer

OptmWiz is hosted as a **prototype Shiny app**:

- Users can explore the workflow with a **sample dataset**.  
- The Random Forest model runs in the backend.  
- Interactive dashboards display acceptance probabilities.  
- Results can be explored visually but not downloaded or reused.  

👉 [**Launch the Demo App**](https://vpprasanth.shinyapps.io/optmwiz/)  

---

## 📊 Demo Walkthrough

1. **Upload Sample Data** – preloaded dataset of quotes.  
2. **Run Optimization** – Random Forest model predicts acceptance probability.  
3. **Visualize Results** – interactive plots and tables show which quotes are likely to be accepted.  
4. **Interpret Variables** – decision tree and variable importance charts highlight key drivers.  

---

## 📈 Impact

- **Strategic Pricing:** Helps BuildSmart anticipate customer behaviour.  
- **Efficiency:** Reduces wasted effort on quotes unlikely to convert.  
- **Transparency:** Provides interpretable decision trees alongside predictive probabilities.  
- **Scalability:** Can incorporate additional parameters (seasonality, bid logs, etc.) to improve accuracy further.  

---

## ⚠️ Disclaimer

This is a **prototype showcase**.  
It is intended for demonstration purposes only.  
The app is hosted with sample data and is **not available for download or reuse**.

---

## 📜 License

GPL-3
