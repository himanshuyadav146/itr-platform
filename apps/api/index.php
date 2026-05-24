<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>ITR Plus - File Your ITR Online</title>
  <style>
    body {
      font-family: 'Segoe UI', sans-serif;
      margin: 0;
      padding: 0;
      background-color: #f4f6f8;
      color: #333;
    }

    header {
      background-color: #0052cc;
      color: #fff;
      padding: 20px 40px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    header h1 {
      margin: 0;
    }

    nav a {
      color: #fff;
      margin-left: 20px;
      text-decoration: none;
      font-weight: bold;
    }

    .hero {
      padding: 60px 40px;
      background-color: #e6f0ff;
      text-align: center;
    }

    .hero h2 {
      font-size: 36px;
      margin-bottom: 20px;
    }

    .hero p {
      font-size: 18px;
      margin-bottom: 30px;
    }

    .hero button {
      padding: 12px 24px;
      font-size: 16px;
      background-color: #0052cc;
      color: #fff;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }

    .section {
      padding: 40px;
      max-width: 1000px;
      margin: auto;
    }

    .section h3 {
      margin-bottom: 20px;
      color: #0052cc;
    }

    .benefits, .testimonials {
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
    }

    .card {
      flex: 1 1 300px;
      background-color: #fff;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    }

    footer {
      background-color: #003366;
      color: #fff;
      text-align: center;
      padding: 20px;
      margin-top: 40px;
    }

    @media (max-width: 768px) {
      .hero h2 {
        font-size: 28px;
      }
      .benefits, .testimonials {
        flex-direction: column;
      }
    }
  </style>
</head>
<body>

  <header>
    <h1>ITR Plus</h1>
    <nav>
      <a href="#">Home</a>
      <a href="#">File Now</a>
      <a href="#">Pricing</a>
      <a href="#">Support</a>
      <a href="#">Login</a>
    </nav>
  </header>

  <div class="hero">
    <h2>File Your Income Tax Return Online – Fast, Safe & Easy</h2>
    <p>Trusted by thousands of individuals and professionals across India. No paperwork. No hassle.</p>
    <button onclick="window.location.href='#'">Start Filing Now</button>
  </div>

  <div class="section">
    <h3>Why Choose ITR Plus?</h3>
    <div class="benefits">
      <div class="card">
        <h4>100% Secure</h4>
        <p>Your data is encrypted and secure with us.</p>
      </div>
      <div class="card">
        <h4>Expert Support</h4>
        <p>Talk to certified tax experts whenever you need help.</p>
      </div>
      <div class="card">
        <h4>Fast Filing</h4>
        <p>File your return in just 5 minutes – it's that easy!</p>
      </div>
    </div>
  </div>

  <div class="section">
    <h3>What Our Users Say</h3>
    <div class="testimonials">
      <div class="card">
        <p>"ITR Plus made filing my ITR a breeze. The UI is simple and support is amazing!"</p>
        <strong>- Rahul M., Delhi</strong>
      </div>
      <div class="card">
        <p>"As a freelancer, tax filing used to be stressful. Now, it’s stress-free."</p>
        <strong>- Priya S., Mumbai</strong>
      </div>
    </div>
  </div>

  <footer>
    <p>&copy; 2025 ITR Plus. All rights reserved. | <a href="privecy-policy.php" style="color: #fff;">Privacy Policy</a></p>
  </footer>

</body>
</html>
